import 'package:flutter/foundation.dart';

import '../../core/services/supabase_service.dart';
import '../models/activity_model.dart';
import '../models/baby_type.dart';

/// Activity 데이터 저장소
/// Supabase activities 테이블과 연동
/// 다중 아기 동시 기록 지원
class ActivityRepository {
  /// 가족의 모든 활동 조회 (최신순)
  Future<List<ActivityModel>> getActivitiesByFamilyId(
    String familyId, {
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await SupabaseService.activities
          .select()
          .eq('family_id', familyId)
          .order('start_time', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((data) => _mapToActivityModel(data)).toList();
    } catch (e) {
      debugPrint('[ERR] [ActivityRepository] Error getting activities: $e');
      rethrow;
    }
  }

  /// 특정 아기의 활동 조회
  Future<List<ActivityModel>> getActivitiesByBabyId(
    String babyId, {
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await SupabaseService.activities
          .select()
          .contains('baby_ids', [babyId])
          .order('start_time', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((data) => _mapToActivityModel(data)).toList();
    } catch (e) {
      debugPrint('[ERR] [ActivityRepository] Error getting baby activities: $e');
      rethrow;
    }
  }

  /// 오늘의 활동 조회
  /// HF2-6: UTC 변환하여 시간대 일관성 유지
  Future<List<ActivityModel>> getTodayActivities(String familyId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // HF2-6: 로컬 시간을 UTC로 변환하여 Supabase 쿼리
      final startUtc = startOfDay.toUtc().toIso8601String();
      final endUtc = endOfDay.toUtc().toIso8601String();

      debugPrint('[DEBUG] [ActivityRepo] Today query: $startUtc ~ $endUtc');

      final response = await SupabaseService.activities
          .select()
          .eq('family_id', familyId)
          .gte('start_time', startUtc)
          .lt('start_time', endUtc)
          .order('start_time', ascending: false);

      return (response as List).map((data) => _mapToActivityModel(data)).toList();
    } catch (e) {
      debugPrint('[ERROR] [ActivityRepository] Error getting today activities: $e');
      rethrow;
    }
  }

  /// 날짜 범위로 활동 조회
  /// HF2-6: UTC 변환하여 시간대 일관성 유지
  Future<List<ActivityModel>> getActivitiesByDateRange(
    String familyId, {
    required DateTime startDate,
    required DateTime endDate,
    String? babyId,
    ActivityType? type,
  }) async {
    try {
      // HF2-6: 로컬 시간을 UTC로 변환하여 Supabase 쿼리
      // Supabase는 UTC로 저장하므로 쿼리도 UTC로 해야 함
      final startUtc = startDate.toUtc().toIso8601String();
      final endUtc = endDate.toUtc().toIso8601String();

      debugPrint('[DEBUG] [ActivityRepo] Query: $startUtc ~ $endUtc');

      var query = SupabaseService.activities
          .select()
          .eq('family_id', familyId)
          .gte('start_time', startUtc)
          .lt('start_time', endUtc);

      if (babyId != null) {
        query = query.contains('baby_ids', [babyId]);
      }

      if (type != null) {
        query = query.eq('type', type.value);
      }

      final response = await query.order('start_time', ascending: false);

      return (response as List).map((data) => _mapToActivityModel(data)).toList();
    } catch (e) {
      debugPrint('[ERR] [ActivityRepository] Error getting activities by date: $e');
      rethrow;
    }
  }

  /// 활동 ID로 조회
  Future<ActivityModel?> getActivityById(String activityId) async {
    try {
      final response = await SupabaseService.activities
          .select()
          .eq('id', activityId)
          .maybeSingle();

      if (response == null) return null;
      return _mapToActivityModel(response);
    } catch (e) {
      debugPrint('[ERR] [ActivityRepository] Error getting activity by id: $e');
      rethrow;
    }
  }

  /// 활동 생성
  Future<ActivityModel> createActivity(ActivityModel activity) async {
    try {
      final data = _mapToSupabaseData(activity);

      final response = await SupabaseService.activities
          .insert(data)
          .select()
          .single();

      debugPrint('[OK] [ActivityRepository] Activity created: ${response['id']}');
      return _mapToActivityModel(response);
    } catch (e) {
      debugPrint('[ERR] [ActivityRepository] Error creating activity: $e');
      rethrow;
    }
  }

  /// 활동 수정
  Future<ActivityModel> updateActivity(ActivityModel activity) async {
    try {
      final data = _mapToSupabaseData(activity);
      data.remove('id');
      data.remove('created_at');

      final response = await SupabaseService.activities
          .update(data)
          .eq('id', activity.id)
          .select()
          .single();

      debugPrint('[OK] [ActivityRepository] Activity updated: ${activity.id}');
      return _mapToActivityModel(response);
    } catch (e) {
      debugPrint('[ERR] [ActivityRepository] Error updating activity: $e');
      rethrow;
    }
  }

  /// 활동 종료 (endTime 설정)
  /// FIX: Sprint 19 FIX: Local → UTC 변환 추가
  Future<ActivityModel> finishActivity(String activityId, [DateTime? endTime]) async {
    try {
      final endTimeUtc = (endTime ?? DateTime.now()).toUtc();  // FIX: toUtc() 추가
      final response = await SupabaseService.activities
          .update({'end_time': endTimeUtc.toIso8601String()})
          .eq('id', activityId)
          .select()
          .single();

      debugPrint('[OK] [ActivityRepository] Activity finished: $activityId');
      return _mapToActivityModel(response);
    } catch (e) {
      debugPrint('[ERR] [ActivityRepository] Error finishing activity: $e');
      rethrow;
    }
  }

  /// 활동 삭제
  Future<void> deleteActivity(String activityId) async {
    try {
      await SupabaseService.activities
          .delete()
          .eq('id', activityId);

      debugPrint('[OK] [ActivityRepository] Activity deleted: $activityId');
    } catch (e) {
      debugPrint('[ERR] [ActivityRepository] Error deleting activity: $e');
      rethrow;
    }
  }

  /// 특정 아기의 진행 중 수면 조회 (end_time IS NULL + type=sleep)
  /// HF-5: BabyTime import 등 외부 경로로 생성된 활성 수면 감지
  /// HF-ghost: 24h 가드 추가 — 24시간 이상 경과한 유령 수면 무시
  Future<ActivityModel?> getActiveSleepForBaby(String babyId) async {
    try {
      final cutoff = DateTime.now()
          .subtract(const Duration(hours: 24))
          .toUtc()
          .toIso8601String();
      final response = await SupabaseService.activities
          .select()
          .contains('baby_ids', [babyId])
          .eq('type', 'sleep')
          .isFilter('end_time', null)
          .gte('start_time', cutoff)
          .order('start_time', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      debugPrint('[OK] [ActivityRepository] Found active sleep for baby: $babyId');
      return _mapToActivityModel(response);
    } catch (e) {
      debugPrint('[ERR] [ActivityRepository] Error getting active sleep: $e');
      return null;
    }
  }

  /// 진행 중인 활동 조회
  Future<List<ActivityModel>> getOngoingActivities(String familyId) async {
    try {
      final response = await SupabaseService.activities
          .select()
          .eq('family_id', familyId)
          .isFilter('end_time', null)
          .order('start_time', ascending: false);

      return (response as List).map((data) => _mapToActivityModel(data)).toList();
    } catch (e) {
      debugPrint('[ERR] [ActivityRepository] Error getting ongoing activities: $e');
      rethrow;
    }
  }

  /// Sprint 19: 전체 기록 존재 여부 확인 (신규 유저 판별)
  Future<bool> hasAnyActivities(String familyId) async {
    try {
      final response = await SupabaseService.activities
          .select('id')
          .eq('family_id', familyId)
          .limit(1);

      final hasAny = (response as List).isNotEmpty;
      debugPrint('[DEBUG] [ActivityRepository] hasAnyActivities($familyId): $hasAny');
      return hasAny;
    } catch (e) {
      debugPrint('[ERR] [ActivityRepository] Error checking hasAnyActivities: $e');
      // 에러 시 true 반환 (신규 유저 Empty State 표시 방지)
      return true;
    }
  }

  /// 마지막 활동 조회 (타입별)
  Future<ActivityModel?> getLastActivity(
    String familyId, {
    String? babyId,
    ActivityType? type,
  }) async {
    try {
      var query = SupabaseService.activities
          .select()
          .eq('family_id', familyId);

      if (babyId != null) {
        query = query.contains('baby_ids', [babyId]);
      }

      if (type != null) {
        query = query.eq('type', type.value);
      }

      final response = await query
          .order('start_time', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return _mapToActivityModel(response);
    } catch (e) {
      debugPrint('[ERR] [ActivityRepository] Error getting last activity: $e');
      rethrow;
    }
  }

  /// DEBUG: 디버그: 모든 활동 조회 (family_id 검증용)
  Future<void> debugCheckActivities(String familyId) async {
    try {
      // 1. 해당 family_id의 활동 개수
      final byFamily = await SupabaseService.activities
          .select()
          .eq('family_id', familyId);
      debugPrint('[DEBUG] [ActivityRepo] Activities with family_id=$familyId: ${(byFamily as List).length}');

      // 2. 전체 활동 개수 (family_id 필터 없이)
      final allActivities = await SupabaseService.activities
          .select()
          .limit(10);
      debugPrint('[DEBUG] [ActivityRepo] Sample of all activities (limit 10):');
      for (final a in (allActivities as List)) {
        debugPrint('   - id: ${a['id']?.toString().substring(0, 8)}..., family_id: ${a['family_id']}, baby_ids: ${a['baby_ids']}');
      }

      // 3. 전체 고유 family_id 목록
      final uniqueFamilies = await SupabaseService.activities
          .select('family_id')
          .limit(100);
      final familyIds = (uniqueFamilies as List).map((e) => e['family_id']).toSet();
      debugPrint('[DEBUG] [ActivityRepo] Unique family_ids in activities: $familyIds');
    } catch (e) {
      debugPrint('[ERR] [ActivityRepo] Debug check error: $e');
    }
  }

  /// sleep_type이 NULL인 수면 레코드 조회 (마이그레이션용)
  Future<List<ActivityModel>> getSleepActivitiesWithNullType(
    String familyId,
  ) async {
    try {
      // data->>'sleep_type' IS NULL인 수면 기록 조회
      // Supabase PostgREST: data->>sleep_type.is.null 필터
      final response = await SupabaseService.activities
          .select()
          .eq('family_id', familyId)
          .eq('type', 'sleep')
          .or('data->>sleep_type.is.null,data->>sleep_type.eq.');

      return (response as List)
          .map((data) => _mapToActivityModel(data))
          .toList();
    } catch (e) {
      debugPrint('[ERR] [ActivityRepository] Error getting null sleep_type: $e');
      return [];
    }
  }

  /// 수면 기록의 data.sleep_type만 업데이트 (마이그레이션용)
  Future<void> updateSleepType(String activityId, String sleepType) async {
    try {
      // 기존 data를 읽어서 sleep_type만 추가
      final existing = await SupabaseService.activities
          .select('data')
          .eq('id', activityId)
          .single();

      final currentData =
          (existing['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final updatedData = <String, dynamic>{
        ...currentData,
        'sleep_type': sleepType,
      };

      await SupabaseService.activities
          .update({'data': updatedData})
          .eq('id', activityId);
    } catch (e) {
      debugPrint('[ERR] [ActivityRepository] Error updating sleep_type: $e');
    }
  }

  // ========================================
  // Private Helpers
  // ========================================

  /// Supabase 응답 -> ActivityModel 변환
  /// FIX: Sprint 19 H-UTC: UTC → Local 변환 추가 (조회 시)
  ActivityModel _mapToActivityModel(Map<String, dynamic> data) {
    return ActivityModel(
      id: data['id'],
      familyId: data['family_id'],
      babyIds: List<String>.from(data['baby_ids'] as List),
      type: ActivityType.fromValue(data['type']),
      // UTC → Local 변환
      startTime: DateTime.parse(data['start_time']).toLocal(),
      endTime: data['end_time'] != null
          ? DateTime.parse(data['end_time']).toLocal()
          : null,
      data: data['data'] as Map<String, dynamic>?,
      notes: data['notes'] as String?,
      createdAt: DateTime.parse(data['created_at']).toLocal(),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at']).toLocal()
          : null,
    );
  }

  /// ActivityModel -> Supabase 데이터 변환
  /// FIX: Sprint 19 FIX: Local → UTC 변환 추가 (저장 시)
  Map<String, dynamic> _mapToSupabaseData(ActivityModel activity) {
    // 디버그 로그 (UTC 변환 확인)
    debugPrint('[UTC-DEBUG] startTime: ${activity.startTime}, isUtc=${activity.startTime.isUtc}');
    debugPrint('[UTC-DEBUG] toUtc(): ${activity.startTime.toUtc()}');

    return {
      'id': activity.id,
      'family_id': activity.familyId,
      'baby_ids': activity.babyIds,
      'type': activity.type.value,
      'start_time': activity.startTime.toUtc().toIso8601String(),  // FIX: toUtc() 추가
      if (activity.endTime != null) 'end_time': activity.endTime!.toUtc().toIso8601String(),  // FIX: toUtc() 추가
      if (activity.data != null) 'data': activity.data,
      if (activity.notes != null) 'notes': activity.notes,
    };
  }
}
