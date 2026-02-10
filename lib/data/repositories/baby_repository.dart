import 'package:flutter/foundation.dart';

import '../../core/services/supabase_service.dart';
import '../models/baby_model.dart';
import '../models/baby_type.dart';

/// Baby 데이터 저장소
/// Supabase babies 테이블과 연동
class BabyRepository {
  /// 가족의 모든 아기 조회
  Future<List<BabyModel>> getBabiesByFamilyId(String familyId) async {
    try {
      final response = await SupabaseService.babies
          .select()
          .eq('family_id', familyId)
          .order('birth_order', ascending: true);

      return (response as List).map((data) => _mapToBabyModel(data)).toList();
    } catch (e) {
      debugPrint('[ERR] [BabyRepository] Error getting babies: $e');
      rethrow;
    }
  }

  /// 아기 ID로 조회
  Future<BabyModel?> getBabyById(String babyId) async {
    try {
      final response = await SupabaseService.babies
          .select()
          .eq('id', babyId)
          .maybeSingle();

      if (response == null) return null;
      return _mapToBabyModel(response);
    } catch (e) {
      debugPrint('[ERR] [BabyRepository] Error getting baby by id: $e');
      rethrow;
    }
  }

  /// 아기 생성
  Future<BabyModel> createBaby(BabyModel baby) async {
    try {
      final data = _mapToSupabaseData(baby);

      final response = await SupabaseService.babies
          .insert(data)
          .select()
          .single();

      debugPrint('[OK] [BabyRepository] Baby created: ${response['id']}');
      return _mapToBabyModel(response);
    } catch (e) {
      debugPrint('[ERR] [BabyRepository] Error creating baby: $e');
      rethrow;
    }
  }

  /// 여러 아기 일괄 생성 (온보딩용)
  Future<List<BabyModel>> createBabies(List<BabyModel> babies) async {
    try {
      final dataList = babies.map((baby) => _mapToSupabaseData(baby)).toList();

      final response = await SupabaseService.babies
          .insert(dataList)
          .select();

      debugPrint('[OK] [BabyRepository] ${babies.length} babies created');
      return (response as List).map((data) => _mapToBabyModel(data)).toList();
    } catch (e) {
      debugPrint('[ERR] [BabyRepository] Error creating babies: $e');
      rethrow;
    }
  }

  /// 아기 정보 수정
  Future<BabyModel> updateBaby(BabyModel baby) async {
    try {
      final data = _mapToSupabaseData(baby);
      data.remove('id'); // ID는 업데이트하지 않음
      data.remove('created_at'); // 생성일은 업데이트하지 않음

      final response = await SupabaseService.babies
          .update(data)
          .eq('id', baby.id)
          .select()
          .single();

      debugPrint('[OK] [BabyRepository] Baby updated: ${baby.id}');
      return _mapToBabyModel(response);
    } catch (e) {
      debugPrint('[ERR] [BabyRepository] Error updating baby: $e');
      rethrow;
    }
  }

  /// 아기 삭제
  Future<void> deleteBaby(String babyId) async {
    try {
      await SupabaseService.babies
          .delete()
          .eq('id', babyId);

      debugPrint('[OK] [BabyRepository] Baby deleted: $babyId');
    } catch (e) {
      debugPrint('[ERR] [BabyRepository] Error deleting baby: $e');
      rethrow;
    }
  }

  /// 가족의 아기 수 조회
  Future<int> getBabyCount(String familyId) async {
    try {
      final response = await SupabaseService.babies
          .select('id')
          .eq('family_id', familyId);

      return (response as List).length;
    } catch (e) {
      debugPrint('[ERR] [BabyRepository] Error getting baby count: $e');
      return 0;
    }
  }

  // ========================================
  // Private Helpers
  // ========================================

  /// Supabase 응답 -> BabyModel 변환
  BabyModel _mapToBabyModel(Map<String, dynamic> data) {
    return BabyModel(
      id: data['id'],
      familyId: data['family_id'],
      name: data['name'],
      birthDate: DateTime.parse(data['birth_date']),
      gender: data['gender'] != null
          ? Gender.fromValue(data['gender'])
          : Gender.unknown,
      gestationalWeeksAtBirth: data['gestational_weeks_at_birth'],
      birthWeightGrams: data['birth_weight_grams'],
      multipleBirthType: data['baby_type'] != null
          ? BabyType.fromValue(data['baby_type'])
          : BabyType.singleton,
      zygosity: data['zygosity'] != null
          ? Zygosity.fromValue(data['zygosity'])
          : null,
      birthOrder: data['birth_order'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : null,
    );
  }

  /// BabyModel -> Supabase 데이터 변환
  Map<String, dynamic> _mapToSupabaseData(BabyModel baby) {
    return {
      'id': baby.id,
      'family_id': baby.familyId,
      'name': baby.name,
      'birth_date': baby.birthDate.toIso8601String().split('T')[0], // DATE 형식
      'gender': baby.gender.value,
      if (baby.gestationalWeeksAtBirth != null)
        'gestational_weeks_at_birth': baby.gestationalWeeksAtBirth,
      if (baby.birthWeightGrams != null)
        'birth_weight_grams': baby.birthWeightGrams,
      'baby_type': baby.multipleBirthType?.value ?? 'singleton',
      if (baby.zygosity != null) 'zygosity': baby.zygosity!.value,
      if (baby.birthOrder != null) 'birth_order': baby.birthOrder,
    };
  }
}
