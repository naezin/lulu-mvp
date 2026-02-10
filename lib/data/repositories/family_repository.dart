import 'package:flutter/foundation.dart';

import '../../core/services/supabase_service.dart';
import '../models/family_model.dart';

/// Family 데이터 저장소
/// family_members 경로 우선, families.user_id 레거시 폴백
class FamilyRepository {
  /// 현재 사용자의 가족 조회
  /// family_members 경로 우선 → 레거시 폴백
  Future<FamilyModel?> getCurrentFamily() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        debugPrint('[ERR] [FamilyRepository] No authenticated user');
        return null;
      }

      // 1. family_members 경로 (v2 방식)
      final memberResult = await SupabaseService.client
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .maybeSingle();

      String? familyId;

      if (memberResult != null) {
        familyId = memberResult['family_id'] as String;
      } else {
        // 2. 레거시 폴백: families.user_id
        debugPrint('[WARN] [FamilyRepository] legacy fallback used - getCurrentFamily');
        final response = await SupabaseService.families
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();

        if (response == null) {
          debugPrint('[INFO] [FamilyRepository] No family found for user');
          return null;
        }

        familyId = response['id'] as String;
      }

      // families 테이블에서 상세 조회
      final familyResponse = await SupabaseService.families
          .select()
          .eq('id', familyId)
          .maybeSingle();

      if (familyResponse == null) {
        debugPrint('[WARN] [FamilyRepository] Family not found by id: $familyId');
        return null;
      }

      // babies 테이블에서 가족의 아기 ID들 조회
      final babiesResponse = await SupabaseService.babies
          .select('id')
          .eq('family_id', familyId);

      final babyIds = (babiesResponse as List)
          .map((b) => b['id'] as String)
          .toList();

      return FamilyModel(
        id: familyResponse['id'],
        userId: familyResponse['user_id'],
        babyIds: babyIds,
        createdAt: DateTime.parse(familyResponse['created_at']),
        updatedAt: familyResponse['updated_at'] != null
            ? DateTime.parse(familyResponse['updated_at'])
            : null,
      );
    } catch (e) {
      debugPrint('[ERR] [FamilyRepository] Error getting family: $e');
      rethrow;
    }
  }

  /// 가족 생성
  /// Family Sharing v3.2: family_members에도 owner로 추가
  Future<FamilyModel> createFamily() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        throw StateError('User must be authenticated to create a family');
      }

      // 1. families 테이블에 INSERT
      final response = await SupabaseService.families
          .insert({
            'user_id': userId,
            'created_by': userId,
          })
          .select()
          .single();

      final familyId = response['id'] as String;
      debugPrint('[OK] [FamilyRepository] Family created: $familyId');

      // 2. family_members에 owner로 INSERT (RLS 필수)
      try {
        await SupabaseService.client.from('family_members').insert({
          'family_id': familyId,
          'user_id': userId,
          'role': 'owner',
        });
        debugPrint('[OK] [FamilyRepository] Family member (owner) created');
      } catch (e) {
        debugPrint('[WARN] [FamilyRepository] family_members insert failed: $e');
        // DB 트리거가 INSERT 시 자동 생성하지만, 실패 로그는 남김
      }

      return FamilyModel(
        id: familyId,
        userId: response['user_id'],
        babyIds: [],
        createdAt: DateTime.parse(response['created_at']),
      );
    } catch (e) {
      debugPrint('[ERR] [FamilyRepository] Error creating family: $e');
      rethrow;
    }
  }

  /// 가족 삭제
  Future<void> deleteFamily(String familyId) async {
    try {
      await SupabaseService.families
          .delete()
          .eq('id', familyId);

      debugPrint('[OK] [FamilyRepository] Family deleted: $familyId');
    } catch (e) {
      debugPrint('[ERR] [FamilyRepository] Error deleting family: $e');
      rethrow;
    }
  }

  /// 가족 존재 여부 확인
  /// family_members 경로 우선 → 레거시 폴백
  Future<bool> hasFamily() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return false;

      // 1. family_members 경로 (v2 방식)
      final memberResult = await SupabaseService.client
          .from('family_members')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (memberResult != null) return true;

      // 2. 레거시 폴백
      debugPrint('[WARN] [FamilyRepository] legacy fallback used - hasFamily');
      final response = await SupabaseService.families
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('[ERR] [FamilyRepository] Error checking family: $e');
      return false;
    }
  }

  /// 가족 ID로 조회
  Future<FamilyModel?> getFamilyById(String familyId) async {
    try {
      final response = await SupabaseService.families
          .select()
          .eq('id', familyId)
          .maybeSingle();

      if (response == null) return null;

      // babies 테이블에서 가족의 아기 ID들 조회
      final babiesResponse = await SupabaseService.babies
          .select('id')
          .eq('family_id', familyId);

      final babyIds = (babiesResponse as List)
          .map((b) => b['id'] as String)
          .toList();

      return FamilyModel(
        id: response['id'],
        userId: response['user_id'],
        babyIds: babyIds,
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: response['updated_at'] != null
            ? DateTime.parse(response['updated_at'])
            : null,
      );
    } catch (e) {
      debugPrint('[ERR] [FamilyRepository] Error getting family by id: $e');
      rethrow;
    }
  }

  // ========================================
  // family_members 자동 등록
  // ========================================

  /// family_members 확인 및 자동 등록
  /// RLS 42501 에러 근본 해결
  Future<void> ensureFamilyMember(String familyId) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      debugPrint('[ERR] [FamilyRepository] No user for ensureFamilyMember');
      return;
    }

    try {
      // 이미 등록되어 있는지 확인
      final existing = await SupabaseService.client
          .from('family_members')
          .select('id')
          .eq('family_id', familyId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        // 없으면 owner로 등록
        await SupabaseService.client.from('family_members').insert({
          'family_id': familyId,
          'user_id': userId,
          'role': 'owner',
        });
        debugPrint('[OK] [FamilyRepository] Auto-registered to family_members');
      } else {
        debugPrint('[OK] [FamilyRepository] Already in family_members');
      }
    } catch (e) {
      debugPrint('[ERR] [FamilyRepository] ensureFamilyMember error: $e');
      // UNIQUE constraint 에러면 무시 (이미 있음)
      if (!e.toString().contains('duplicate') &&
          !e.toString().contains('unique') &&
          !e.toString().contains('23505')) {
        // 에러지만 upsert로 재시도
        try {
          await SupabaseService.client.from('family_members').upsert(
            {
              'family_id': familyId,
              'user_id': userId,
              'role': 'owner',
            },
            onConflict: 'family_id,user_id',
          );
          debugPrint('[OK] [FamilyRepository] Upsert succeeded');
        } catch (e2) {
          debugPrint('[ERR] [FamilyRepository] Upsert also failed: $e2');
        }
      }
    }
  }

  /// family_members를 통해 가족 조회 (RLS 호환)
  Future<FamilyModel?> getFamilyByMembership() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return null;

      // family_members 통해 조회
      final memberResponse = await SupabaseService.client
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (memberResponse != null) {
        final familyId = memberResponse['family_id'] as String;
        return await getFamilyById(familyId);
      }

      // 레거시 폴백
      debugPrint('[WARN] [FamilyRepository] legacy fallback used - getFamilyByMembership');
      return await getCurrentFamily();
    } catch (e) {
      debugPrint('[ERR] [FamilyRepository] getFamilyByMembership error: $e');
      return null;
    }
  }

  /// 전체 데이터 초기화 (설정 > 데이터 초기화)
  ///
  /// activities, babies, family_invites, family_members, families 순서로 삭제.
  /// 로그아웃은 호출측에서 처리.
  Future<void> resetAllData() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    // 1. family_id 찾기 (family_members 우선, families 폴백)
    String? familyId;

    try {
      final memberData = await SupabaseService.client
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (memberData != null) {
        familyId = memberData['family_id'] as String?;
        debugPrint('[OK] Found family via family_members: $familyId');
      }
    } catch (e) {
      debugPrint('[WARN] family_members query failed: $e');
    }

    if (familyId == null) {
      debugPrint('[WARN] [FamilyRepository] legacy fallback used - resetAllData');
      final familyData = await SupabaseService.families
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (familyData != null) {
        familyId = familyData['id'] as String?;
        debugPrint('[OK] Found family via families.user_id: $familyId');
      }
    }

    if (familyId != null) {
      debugPrint('[INFO] Deleting all data for family: $familyId');

      // 2. activities
      await SupabaseService.activities
          .delete()
          .eq('family_id', familyId);
      debugPrint('[OK] Activities deleted');

      // 3. babies
      await SupabaseService.babies
          .delete()
          .eq('family_id', familyId);
      debugPrint('[OK] Babies deleted');

      // 4. family_invites
      try {
        await SupabaseService.client
            .from('family_invites')
            .delete()
            .eq('family_id', familyId);
        debugPrint('[OK] Family invites deleted');
      } catch (e) {
        debugPrint('[WARN] family_invites deletion failed: $e');
      }

      // 5. family_members
      try {
        await SupabaseService.client
            .from('family_members')
            .delete()
            .eq('family_id', familyId);
        debugPrint('[OK] Family members deleted');
      } catch (e) {
        debugPrint('[WARN] family_members deletion failed: $e');
      }

      // 6. families
      await SupabaseService.families
          .delete()
          .eq('id', familyId);
      debugPrint('[OK] Family deleted');
    }

    debugPrint('[OK] All data reset complete');
  }
}
