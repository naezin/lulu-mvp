import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_service.dart';

/// Family 동기화 서비스
/// 로컬 Family와 Supabase Family 동기화
///
/// families + family_members 테이블 동시 사용 (RLS 필수)
/// families 생성/복원 시 반드시 family_members에 owner 등록
class FamilySyncService {
  static final FamilySyncService _instance = FamilySyncService._internal();
  factory FamilySyncService() => _instance;
  FamilySyncService._internal();

  static FamilySyncService get instance => _instance;

  /// 앱 시작 시 호출 - 로컬 family와 Supabase 동기화
  /// 반환: 동기화된 familyId (없으면 null)
  Future<String?> ensureFamilyExists() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      debugPrint('[WARN] FamilySyncService: No user logged in');
      return null;
    }

    debugPrint('[INFO] FamilySyncService: Ensuring family exists for user $userId');

    try {
      // 1. family_members 테이블에서 사용자의 family 조회 (v2 방식)
      final memberResult = await SupabaseService.client
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (memberResult != null) {
        final familyId = memberResult['family_id'] as String;
        debugPrint('[OK] FamilySyncService: Found family via family_members: $familyId');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('family_id', familyId);
        await prefs.setString('onboarding_family_id', familyId);

        return familyId;
      }

      // 2. families.user_id 레거시 폴백
      final result = await SupabaseService.client
          .from('families')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (result != null) {
        final familyId = result['id'] as String;
        debugPrint('[WARN] FamilySyncService: Found family via legacy user_id: $familyId');

        // 레거시 → family_members 자동 등록
        await SupabaseService.client.from('family_members').upsert({
          'family_id': familyId,
          'user_id': userId,
          'role': 'owner',
        });
        debugPrint('[OK] FamilySyncService: Auto-registered legacy user to family_members');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('family_id', familyId);
        await prefs.setString('onboarding_family_id', familyId);

        return familyId;
      }

      // 2. Supabase에 없으면 로컬 family_id 확인 (여러 키 시도)
      final prefs = await SharedPreferences.getInstance();
      String? localFamilyId = prefs.getString('family_id');

      // onboarding_family에서 JSON으로 저장된 경우도 확인
      if (localFamilyId == null) {
        final onboardingFamilyJson = prefs.getString('onboarding_family');
        if (onboardingFamilyJson != null) {
          try {
            final familyMap = jsonDecode(onboardingFamilyJson) as Map<String, dynamic>;
            localFamilyId = familyMap['id'] as String?;
            debugPrint('[INFO] FamilySyncService: Found family ID from onboarding_family JSON: $localFamilyId');
          } catch (e) {
            debugPrint('[WARN] FamilySyncService: Failed to parse onboarding_family JSON: $e');
          }
        }
      }

      if (localFamilyId != null) {
        debugPrint('[INFO] FamilySyncService: Local family found, syncing to Supabase: $localFamilyId');
        // 로컬에는 있는데 Supabase에 없음 → Supabase에 생성
        await _createFamilyInSupabase(localFamilyId, userId);
        return localFamilyId;
      }

      debugPrint('[WARN] FamilySyncService: No family found locally or in Supabase');
      return null;
    } catch (e) {
      debugPrint('[ERROR] FamilySyncService.ensureFamilyExists: $e');
      return null;
    }
  }

  /// Supabase에 Family 생성 (로컬 데이터 기반)
  /// families + family_members 동시 사용 (RLS 필수)
  Future<void> _createFamilyInSupabase(String familyId, String userId) async {
    try {
      // Family 생성 (upsert - 이미 있으면 업데이트)
      await SupabaseService.client.from('families').upsert({
        'id': familyId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('[OK] FamilySyncService: Family created/updated in Supabase');

      // family_members에 owner 등록 (RLS 필수 - 트리거 의존 금지)
      await SupabaseService.client.from('family_members').upsert({
        'family_id': familyId,
        'user_id': userId,
        'role': 'owner',
      });
      debugPrint('[OK] FamilySyncService: Family member registered');

      // 로컬 babies도 Supabase에 동기화
      await _syncBabiesToSupabase(familyId);
    } catch (e) {
      debugPrint('[ERROR] FamilySyncService._createFamilyInSupabase: $e');
      rethrow;
    }
  }

  /// 로컬 Babies를 Supabase에 동기화
  Future<void> _syncBabiesToSupabase(String familyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final babiesJson = prefs.getString('onboarding_babies');

      if (babiesJson == null) {
        debugPrint('[INFO] FamilySyncService: No local babies to sync');
        return;
      }

      final babiesList = jsonDecode(babiesJson) as List;
      debugPrint('[INFO] FamilySyncService: Syncing ${babiesList.length} babies to Supabase');

      for (final babyMap in babiesList) {
        final baby = babyMap as Map<String, dynamic>;

        await SupabaseService.client.from('babies').upsert({
          'id': baby['id'],
          'family_id': familyId,
          'name': baby['name'],
          'birth_date': baby['birthDate'],
          'gender': baby['gender'],
          'gestational_weeks_at_birth': baby['gestationalWeeks'],
          'birth_weight_grams': baby['birthWeightGrams'],
          'baby_type': baby['multipleBirthType'] ?? 'singleton',
          'birth_order': baby['birthOrder'],
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      debugPrint('[OK] FamilySyncService: Babies synced to Supabase');
    } catch (e) {
      debugPrint('[ERROR] FamilySyncService._syncBabiesToSupabase: $e');
      // babies 동기화 실패해도 계속 진행
    }
  }

  /// Family ID 조회 (로컬 또는 Supabase)
  Future<String?> getFamilyId() async {
    // 먼저 로컬 확인
    final prefs = await SharedPreferences.getInstance();
    String? localFamilyId = prefs.getString('family_id');

    // onboarding_family에서 JSON으로 저장된 경우도 확인
    if (localFamilyId == null) {
      final onboardingFamilyJson = prefs.getString('onboarding_family');
      if (onboardingFamilyJson != null) {
        try {
          final familyMap = jsonDecode(onboardingFamilyJson) as Map<String, dynamic>;
          localFamilyId = familyMap['id'] as String?;
        } catch (e) {
          debugPrint('[WARN] FamilySyncService.getFamilyId: Failed to parse onboarding_family JSON');
        }
      }
    }

    if (localFamilyId != null) {
      return localFamilyId;
    }

    // 로컬에 없으면 Supabase에서 확인
    final userId = SupabaseService.currentUserId;
    if (userId == null) return null;

    try {
      // family_members 테이블에서 조회 (v2 방식)
      final memberResult = await SupabaseService.client
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (memberResult != null) {
        return memberResult['family_id'] as String?;
      }

      // 레거시 폴백: families.user_id
      final result = await SupabaseService.client
          .from('families')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return result?['id'] as String?;
    } catch (e) {
      debugPrint('[ERROR] FamilySyncService.getFamilyId: $e');
      return null;
    }
  }
}
