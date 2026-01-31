import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/models.dart';

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
  Future<void> saveOnboardingData({
    required FamilyModel family,
    required List<BabyModel> babies,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // FamilyModel 저장
      final familyJson = jsonEncode(family.toJson());
      await prefs.setString(_keyFamily, familyJson);

      // BabyModel 리스트 저장
      final babiesJson = jsonEncode(babies.map((b) => b.toJson()).toList());
      await prefs.setString(_keyBabies, babiesJson);

      // 완료 플래그 저장
      await prefs.setBool(_keyCompleted, true);

      debugPrint('[OK] [OnboardingDataService] Data saved: family=${family.id}, babies=${babies.length}');
    } catch (e) {
      debugPrint('❌ [OnboardingDataService] Save error: $e');
      rethrow;
    }
  }

  /// 온보딩 완료 여부 확인
  Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyCompleted) ?? false;
    } catch (e) {
      debugPrint('❌ [OnboardingDataService] Check error: $e');
      return false;
    }
  }

  /// 저장된 Family 데이터 로드
  Future<FamilyModel?> loadFamily() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final familyJson = prefs.getString(_keyFamily);

      if (familyJson == null) return null;

      final familyMap = jsonDecode(familyJson) as Map<String, dynamic>;
      return FamilyModel.fromJson(familyMap);
    } catch (e) {
      debugPrint('❌ [OnboardingDataService] Load family error: $e');
      return null;
    }
  }

  /// 저장된 Babies 데이터 로드
  Future<List<BabyModel>> loadBabies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final babiesJson = prefs.getString(_keyBabies);

      if (babiesJson == null) return [];

      final babiesList = jsonDecode(babiesJson) as List;
      return babiesList
          .map((json) => BabyModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ [OnboardingDataService] Load babies error: $e');
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
      debugPrint('❌ [OnboardingDataService] Clear error: $e');
      rethrow;
    }
  }
}
