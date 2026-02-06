import 'package:flutter/foundation.dart';

import '../../core/services/supabase_service.dart';
import '../models/activity_model.dart';
import '../models/baby_type.dart';

/// Activity 데이터 저장소
/// Supabase activities 테이블과 연동
/// 다중 아기 동시 기록 지원
///
/// HF3-v3: 시간대 아키텍처 수정
/// - 저장: toUtc().toIso8601String() (명시적 UTC)
/// - 조회: toUtc().toIso8601String() (UTC로 쿼리)
/// - 파싱: DateTime.parse().toLocal() (UTC → 로컬 변환)
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
      debugPrint('❌ [ActivityRepository] Error getting activities: $e');
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
      debugPrint('❌ [ActivityRepository] Error getting baby activities: $e');
      rethrow;
    }
  }

  /// 오늘의 활동 조회
  /// HF7-FIX: 정확한 날짜 범위 필터링 (클라이언트 필터링)
  Future<List<ActivityModel>> getTodayActivities(String familyId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // HF7: UTC 변환 - 어제부터 오늘 끝까지 (overnight sleep 포함)
      final queryStartUtc = startOfDay.subtract(const Duration(days: 1)).toUtc().toIso8601String();
      final endUtc = endOfDay.toUtc().toIso8601String();

      debugPrint('[DEBUG] [ActivityRepo] Today query: $queryStartUtc ~ $endUtc (UTC)');

      // HF7-FIX: 어제~오늘 범위로 조회 후 클라이언트에서 정확히 필터링
      final response = await SupabaseService.activities
          .select()
          .eq('family_id', familyId)
          .gte('start_time', queryStartUtc)
          .lt('start_time', endUtc)
          .order('start_time', ascending: false);

      debugPrint('[DEBUG] [ActivityRepo] Today raw: ${(response as List).length} activities');

      // 클라이언트 필터링
      final allActivities = response.map((data) => _mapToActivityModel(data)).toList();
      final filtered = allActivities.where((a) {
        final actStart = a.startTime;
        final actEnd = a.endTime;

        if (actEnd != null) {
          // Duration 활동: 오늘과 겹치는지 확인
          return actStart.isBefore(endOfDay) && actEnd.isAfter(startOfDay);
        } else {
          // Instant 활동: 시작 시간이 오늘인지 확인
          return !actStart.isBefore(startOfDay) && actStart.isBefore(endOfDay);
        }
      }).toList();

      debugPrint('[DEBUG] [ActivityRepo] Today filtered: ${filtered.length} activities');
      return filtered;
    } catch (e) {
      debugPrint('[ERROR] [ActivityRepository] Error getting today activities: $e');
      rethrow;
    }
  }

  /// 날짜 범위로 활동 조회
  /// HF7-FIX: 정확한 날짜 범위 필터링
  ///
  /// 조건:
  /// - Duration 활동 (수면/놀이): 시작 < endDate AND 종료 > startDate (겹치는 구간)
  /// - 순간 이벤트 (수유/기저귀/건강): 시작 >= startDate AND 시작 < endDate
  ///
  /// PostgREST 제약으로 복잡한 OR 조건은 클라이언트에서 필터링
  Future<List<ActivityModel>> getActivitiesByDateRange(
    String familyId, {
    required DateTime startDate,
    required DateTime endDate,
    String? babyId,
    ActivityType? type,
  }) async {
    try {
      // HF7: UTC 변환
      final startUtc = startDate.toUtc().toIso8601String();
      final endUtc = endDate.toUtc().toIso8601String();

      debugPrint('[DEBUG] [ActivityRepo] Date range query: $startUtc ~ $endUtc');

      // HF7-FIX: 서버에서 최대한 필터링 후 클라이언트에서 정확히 필터링
      // Duration 활동(수면/놀이)은 전날 시작해서 오늘 끝날 수 있으므로 startDate - 1일부터 조회
      final queryStartUtc = startDate.subtract(const Duration(days: 1)).toUtc().toIso8601String();
      debugPrint('[DEBUG] [ActivityRepo] Query range: $queryStartUtc ~ $endUtc (UTC)');

      var query = SupabaseService.activities
          .select()
          .eq('family_id', familyId)
          .gte('start_time', queryStartUtc)  // startDate - 1일 이후 시작
          .lt('start_time', endUtc);          // endDate 전에 시작

      if (babyId != null) {
        query = query.contains('baby_ids', [babyId]);
      }

      if (type != null) {
        query = query.eq('type', type.value);
      }

      final response = await query.order('start_time', ascending: false);

      debugPrint('[DEBUG] [ActivityRepo] Raw loaded: ${(response as List).length} activities');
      debugPrint('[DEBUG] [ActivityRepo] Filter range: $startDate ~ $endDate (local)');

      // HF7-FIX: 클라이언트에서 정확한 날짜 범위 필터링
      final allActivities = response.map((data) => _mapToActivityModel(data)).toList();
      final filtered = allActivities.where((a) {
        final actStart = a.startTime;
        final actEnd = a.endTime;

        bool include = false;
        if (actEnd != null) {
          // Duration 활동: 해당 날짜 범위와 겹치는지 확인
          // 시작 < endDate AND 종료 > startDate
          include = actStart.isBefore(endDate) && actEnd.isAfter(startDate);
        } else {
          // Instant 활동: 시작 시간이 날짜 범위 내에 있는지 확인
          include = !actStart.isBefore(startDate) && actStart.isBefore(endDate);
        }

        debugPrint('[DEBUG] [Filter] ${a.type.name} start=$actStart end=$actEnd -> include=$include');
        return include;
      }).toList();

      debugPrint('[DEBUG] [ActivityRepo] Filtered: ${filtered.length} activities');
      return filtered;
    } catch (e) {
      debugPrint('[ERROR] [ActivityRepository] Error getting activities by date: $e');
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
      debugPrint('❌ [ActivityRepository] Error getting activity by id: $e');
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
      debugPrint('❌ [ActivityRepository] Error creating activity: $e');
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
      debugPrint('❌ [ActivityRepository] Error updating activity: $e');
      rethrow;
    }
  }

  /// 활동 종료 (endTime 설정)
  /// HF3-v3: UTC로 저장
  Future<ActivityModel> finishActivity(String activityId, [DateTime? endTime]) async {
    try {
      final endTimeUtc = (endTime ?? DateTime.now()).toUtc().toIso8601String();
      final response = await SupabaseService.activities
          .update({'end_time': endTimeUtc})
          .eq('id', activityId)
          .select()
          .single();

      debugPrint('[OK] [ActivityRepository] Activity finished: $activityId');
      return _mapToActivityModel(response);
    } catch (e) {
      debugPrint('❌ [ActivityRepository] Error finishing activity: $e');
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
      debugPrint('❌ [ActivityRepository] Error deleting activity: $e');
      rethrow;
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
      debugPrint('❌ [ActivityRepository] Error getting ongoing activities: $e');
      rethrow;
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
      debugPrint('❌ [ActivityRepository] Error getting last activity: $e');
      rethrow;
    }
  }

  /// 🔍 디버그: 모든 활동 조회 (family_id 검증용)
  Future<void> debugCheckActivities(String familyId) async {
    try {
      // 1. 해당 family_id의 활동 개수
      final byFamily = await SupabaseService.activities
          .select()
          .eq('family_id', familyId);
      debugPrint('🔍 [ActivityRepo] Activities with family_id=$familyId: ${(byFamily as List).length}');

      // 2. 전체 활동 개수 (family_id 필터 없이)
      final allActivities = await SupabaseService.activities
          .select()
          .limit(10);
      debugPrint('🔍 [ActivityRepo] Sample of all activities (limit 10):');
      for (final a in (allActivities as List)) {
        debugPrint('   - id: ${a['id']?.toString().substring(0, 8)}..., family_id: ${a['family_id']}, baby_ids: ${a['baby_ids']}');
      }

      // 3. 전체 고유 family_id 목록
      final uniqueFamilies = await SupabaseService.activities
          .select('family_id')
          .limit(100);
      final familyIds = (uniqueFamilies as List).map((e) => e['family_id']).toSet();
      debugPrint('🔍 [ActivityRepo] Unique family_ids in activities: $familyIds');
    } catch (e) {
      debugPrint('❌ [ActivityRepo] Debug check error: $e');
    }
  }

  // ========================================
  // Private Helpers
  // ========================================

  /// Supabase 응답 -> ActivityModel 변환
  /// HF3-v3: UTC -> 로컬 시간 변환
  ActivityModel _mapToActivityModel(Map<String, dynamic> data) {
    final startTimeRaw = data['start_time'] as String;
    final startTime = _parseTimestamp(startTimeRaw);

    final endTimeRaw = data['end_time'] as String?;
    final endTime = endTimeRaw != null ? _parseTimestamp(endTimeRaw) : null;

    debugPrint('[DEBUG] [ActivityRepo] Loaded: raw=$startTimeRaw -> local=$startTime');

    return ActivityModel(
      id: data['id'],
      familyId: data['family_id'],
      babyIds: List<String>.from(data['baby_ids'] as List),
      type: ActivityType.fromValue(data['type']),
      startTime: startTime,
      endTime: endTime,
      data: data['data'] as Map<String, dynamic>?,
      notes: data['notes'] as String?,
      createdAt: _parseTimestamp(data['created_at'] as String),
      updatedAt: data['updated_at'] != null
          ? _parseTimestamp(data['updated_at'] as String)
          : null,
    );
  }

  /// HF3-v3: timestamp 파싱 - UTC -> 로컬 변환
  /// Supabase timestamptz는 UTC로 저장/반환
  /// 앱에서는 로컬 시간으로 표시
  DateTime _parseTimestamp(String raw) {
    // Supabase에서 받은 UTC 시간을 로컬 시간으로 변환
    return DateTime.parse(raw).toLocal();
  }

  /// ActivityModel -> Supabase 데이터 변환
  /// HF3-v3: UTC로 저장
  Map<String, dynamic> _mapToSupabaseData(ActivityModel activity) {
    // 로컬 시간을 UTC로 변환하여 저장
    final startTimeUtc = activity.startTime.toUtc().toIso8601String();
    final endTimeUtc = activity.endTime?.toUtc().toIso8601String();

    debugPrint('[DEBUG] [ActivityRepo] Saving: ${activity.startTime} -> $startTimeUtc');

    return {
      'id': activity.id,
      'family_id': activity.familyId,
      'baby_ids': activity.babyIds,
      'type': activity.type.value,
      'start_time': startTimeUtc,
      if (endTimeUtc != null) 'end_time': endTimeUtc,
      if (activity.data != null) 'data': activity.data,
      if (activity.notes != null) 'notes': activity.notes,
    };
  }
}
