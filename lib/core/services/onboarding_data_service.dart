import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/models.dart';
import '../../data/repositories/family_repository.dart';
import '../../data/repositories/baby_repository.dart';
import 'supabase_service.dart';

/// 온보딩 데이터 영속성 서비스
///
/// BUG-001: Navigator.pushReplacement 시 Provider 데이터 유실 방지
/// SharedPreferences를 사용하여 온보딩 완료 데이터를 저장/복원
class OnboardingDataService {
  static const String _keyFamily = 'onboarding_family';
  static const String _keyBabies = 'onboarding_babies';
  static const String _keyCompleted = 'onboarding_completed';

  static final OnboardingDataService _instance = OnboardingDataService._internal();
  factory OnboardingDataService() => _instance;
  OnboardingDataService._internal();

  static OnboardingDataService get instance => _instance;

  /// 온보딩 완료 데이터 저장
  /// Supabase + SharedPreferences 동시 저장
  /// Returns the synchronized FamilyModel with Supabase-generated familyId.
  /// Callers MUST use the returned family for HomeProvider.setFamily()
  /// to ensure in-memory familyId matches Supabase.
  Future<FamilyModel> saveOnboardingData({
    required FamilyModel family,
    required List<BabyModel> babies,
  }) async {
    try {
      // 1. Supabase에 저장 (인증된 경우에만)
      // _saveToSupabase returns the Supabase-generated familyId,
      // which may differ from the local family.id (UUID mismatch fix).
      String effectiveFamilyId = family.id;
      final userId = SupabaseService.currentUserId;
      if (userId != null) {
        final supabaseFamilyId = await _saveToSupabase(
          family: family,
          babies: babies,
          userId: userId,
        );
        if (supabaseFamilyId != null) {
          effectiveFamilyId = supabaseFamilyId;
        }
      } else {
        debugPrint('[WARN] [OnboardingDataService] No authenticated user, skipping Supabase save');
      }

      // 2. Synchronize family object with Supabase familyId
      final synchronizedFamily = effectiveFamilyId != family.id
          ? family.copyWith(id: effectiveFamilyId)
          : family;

      // 3. SharedPreferences에 로컬 저장 (백업)
      final prefs = await SharedPreferences.getInstance();

      final familyJson = jsonEncode(synchronizedFamily.toJson());
      await prefs.setString(_keyFamily, familyJson);

      // IMPORTANT: Supabase familyId 사용 (로컬 UUID가 아닌 DB 실제 ID)
      await prefs.setString('family_id', effectiveFamilyId);
      debugPrint('[INFO] [OnboardingDataService] Saved family_id: $effectiveFamilyId');

      // BabyModel 리스트 저장
      final babiesJson = jsonEncode(babies.map((b) => b.toJson()).toList());
      await prefs.setString(_keyBabies, babiesJson);

      // 완료 플래그 저장
      await prefs.setBool(_keyCompleted, true);

      debugPrint('[OK] [OnboardingDataService] Data saved: family=${synchronizedFamily.id}, babies=${babies.length}');

      // Return synchronized family so callers can update in-memory state
      return synchronizedFamily;
    } catch (e) {
      debugPrint('[ERR] [OnboardingDataService] Save error: $e');
      rethrow;
    }
  }

  /// Supabase에 family/babies 데이터 저장
  /// Returns the Supabase-generated familyId (may differ from local family.id)
  Future<String?> _saveToSupabase({
    required FamilyModel family,
    required List<BabyModel> babies,
    required String userId,
  }) async {
    try {
      final familyRepo = FamilyRepository();
      final babyRepo = BabyRepository();

      // 1. 기존 family 확인
      final existingFamily = await familyRepo.getCurrentFamily();

      String familyId;
      if (existingFamily != null) {
        // 이미 family가 있으면 그 ID 사용
        familyId = existingFamily.id;
        debugPrint('[INFO] [OnboardingDataService] Using existing family: $familyId');
      } else {
        // 새 family 생성 (family_members INSERT 포함)
        final createdFamily = await familyRepo.createFamily();
        familyId = createdFamily.id;
        debugPrint('[OK] [OnboardingDataService] Created family in Supabase: $familyId');
      }

      // 2. babies 저장 (familyId 업데이트)
      final updatedBabies = babies.map((baby) => BabyModel(
        id: baby.id,
        familyId: familyId, // Supabase에서 생성된 familyId 사용
        name: baby.name,
        birthDate: baby.birthDate,
        gender: baby.gender,
        gestationalWeeksAtBirth: baby.gestationalWeeksAtBirth,
        birthWeightGrams: baby.birthWeightGrams,
        multipleBirthType: baby.multipleBirthType,
        zygosity: baby.zygosity,
        birthOrder: baby.birthOrder,
        createdAt: baby.createdAt,
        updatedAt: baby.updatedAt,
      )).toList();

      await babyRepo.createBabies(updatedBabies);
      debugPrint('[OK] [OnboardingDataService] Created ${babies.length} babies in Supabase');

      // Return the Supabase familyId so caller can sync local storage
      return familyId;
    } catch (e) {
      debugPrint('[ERR] [OnboardingDataService] Supabase save error: $e');
      // Supabase 저장 실패해도 로컬 저장은 계속 진행
      // rethrow 하지 않음
      return null;
    }
  }

  /// 온보딩 완료 여부 확인
  Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyCompleted) ?? false;
    } catch (e) {
      debugPrint('[ERR] [OnboardingDataService] Check error: $e');
      return false;
    }
  }

  /// 저장된 Family 데이터 로드
  /// BUG-DATA-01 FIX: Supabase 우선, 로컬 fallback
  Future<FamilyModel?> loadFamily() async {
    try {
      // 1. Supabase에서 먼저 시도 (인증된 경우)
      final userId = SupabaseService.currentUserId;
      if (userId != null) {
        try {
          final familyRepo = FamilyRepository();
          final supabaseFamily = await familyRepo.getCurrentFamily();
          if (supabaseFamily != null) {
            debugPrint('[OK] [OnboardingDataService] Loaded family from Supabase: ${supabaseFamily.id}');

            // 로컬에도 동기화
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('family_id', supabaseFamily.id);

            return supabaseFamily;
          }
        } catch (e) {
          debugPrint('[WARN] [OnboardingDataService] Supabase family load failed: $e');
        }
      }

      // 2. Supabase 실패 시 로컬에서 로드 (fallback)
      final prefs = await SharedPreferences.getInstance();
      final familyJson = prefs.getString(_keyFamily);

      if (familyJson == null) return null;

      final familyMap = jsonDecode(familyJson) as Map<String, dynamic>;
      debugPrint('[INFO] [OnboardingDataService] Loaded family from local: ${familyMap['id']}');
      return FamilyModel.fromJson(familyMap);
    } catch (e) {
      debugPrint('[ERR] [OnboardingDataService] Load family error: $e');
      return null;
    }
  }

  /// 저장된 Babies 데이터 로드
  /// BUG-DATA-01 FIX: Supabase 우선, 로컬 fallback
  Future<List<BabyModel>> loadBabies() async {
    try {
      // 1. Supabase에서 먼저 시도 (인증된 경우)
      final userId = SupabaseService.currentUserId;
      if (userId != null) {
        try {
          final familyRepo = FamilyRepository();
          final supabaseFamily = await familyRepo.getCurrentFamily();
          if (supabaseFamily != null) {
            final babyRepo = BabyRepository();
            final supabaseBabies = await babyRepo.getBabiesByFamilyId(supabaseFamily.id);
            if (supabaseBabies.isNotEmpty) {
              debugPrint('[OK] [OnboardingDataService] Loaded ${supabaseBabies.length} babies from Supabase');
              return supabaseBabies;
            }
          }
        } catch (e) {
          debugPrint('[WARN] [OnboardingDataService] Supabase babies load failed: $e');
        }
      }

      // 2. Supabase 실패 시 로컬에서 로드 (fallback)
      final prefs = await SharedPreferences.getInstance();
      final babiesJson = prefs.getString(_keyBabies);

      if (babiesJson == null) return [];

      final babiesList = jsonDecode(babiesJson) as List;
      debugPrint('[INFO] [OnboardingDataService] Loaded ${babiesList.length} babies from local');
      return babiesList
          .map((json) => BabyModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ERR] [OnboardingDataService] Load babies error: $e');
      return [];
    }
  }

  /// 모든 온보딩 데이터 삭제 (로그아웃/리셋용)
  Future<void> clearOnboardingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyFamily);
      await prefs.remove(_keyBabies);
      await prefs.remove(_keyCompleted);

      debugPrint('[OK] [OnboardingDataService] Data cleared');
    } catch (e) {
      debugPrint('[ERR] [OnboardingDataService] Clear error: $e');
      rethrow;
    }
  }
}
