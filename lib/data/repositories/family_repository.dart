import 'package:flutter/foundation.dart';

import '../../core/services/supabase_service.dart';
import '../models/family_model.dart';

/// Family 데이터 저장소
/// Supabase families 테이블과 연동
class FamilyRepository {
  /// 현재 사용자의 가족 조회
  Future<FamilyModel?> getCurrentFamily() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        debugPrint('❌ [FamilyRepository] No authenticated user');
        return null;
      }

      final response = await SupabaseService.families
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint('📭 [FamilyRepository] No family found for user');
        return null;
      }

      // babies 테이블에서 가족의 아기 ID들 조회
      final babiesResponse = await SupabaseService.babies
          .select('id')
          .eq('family_id', response['id']);

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
      debugPrint('❌ [FamilyRepository] Error getting family: $e');
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

      // 2. family_members에 owner로 INSERT (Family Sharing v3.2)
      try {
        await SupabaseService.client.from('family_members').insert({
          'family_id': familyId,
          'user_id': userId,
          'role': 'owner',
        });
        debugPrint('[OK] [FamilyRepository] Family member (owner) created');
      } catch (e) {
        debugPrint('[WARN] [FamilyRepository] family_members insert failed: $e');
        // 실패해도 계속 진행 (레거시 호환)
      }

      return FamilyModel(
        id: familyId,
        userId: response['user_id'],
        babyIds: [],
        createdAt: DateTime.parse(response['created_at']),
      );
    } catch (e) {
      debugPrint('❌ [FamilyRepository] Error creating family: $e');
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
      debugPrint('❌ [FamilyRepository] Error deleting family: $e');
      rethrow;
    }
  }

  /// 가족 존재 여부 확인
  Future<bool> hasFamily() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return false;

      final response = await SupabaseService.families
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('❌ [FamilyRepository] Error checking family: $e');
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
      debugPrint('❌ [FamilyRepository] Error getting family by id: $e');
      rethrow;
    }
  }

  // ========================================
  // 🆕 HOTFIX: family_members 자동 등록
  // ========================================

  /// family_members 확인 및 자동 등록
  /// RLS 42501 에러 근본 해결
  Future<void> ensureFamilyMember(String familyId) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      debugPrint('❌ [FamilyRepository] No user for ensureFamilyMember');
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
        debugPrint('✅ [FamilyRepository] Auto-registered to family_members');
      } else {
        debugPrint('✅ [FamilyRepository] Already in family_members');
      }
    } catch (e) {
      debugPrint('❌ [FamilyRepository] ensureFamilyMember error: $e');
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
          debugPrint('✅ [FamilyRepository] Upsert succeeded');
        } catch (e2) {
          debugPrint('❌ [FamilyRepository] Upsert also failed: $e2');
        }
      }
    }
  }

  /// family_members를 통해 가족 조회 (RLS 호환)
  Future<FamilyModel?> getFamilyByMembership() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return null;

      // 방법 1: family_members 통해 조회
      final memberResponse = await SupabaseService.client
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (memberResponse != null) {
        final familyId = memberResponse['family_id'] as String;
        return await getFamilyById(familyId);
      }

      // 방법 2: 레거시 (families.user_id) 체크
      return await getCurrentFamily();
    } catch (e) {
      debugPrint('❌ [FamilyRepository] getFamilyByMembership error: $e');
      return null;
    }
  }
}
