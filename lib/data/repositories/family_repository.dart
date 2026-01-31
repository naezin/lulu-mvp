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
  Future<FamilyModel> createFamily() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        throw StateError('User must be authenticated to create a family');
      }

      final response = await SupabaseService.families
          .insert({'user_id': userId})
          .select()
          .single();

      debugPrint('[OK] [FamilyRepository] Family created: ${response['id']}');

      return FamilyModel(
        id: response['id'],
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
}
