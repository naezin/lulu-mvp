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
  Future<List<ActivityModel>> getTodayActivities(String familyId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await SupabaseService.activities
          .select()
          .eq('family_id', familyId)
          .gte('start_time', startOfDay.toIso8601String())
          .lt('start_time', endOfDay.toIso8601String())
          .order('start_time', ascending: false);

      return (response as List).map((data) => _mapToActivityModel(data)).toList();
    } catch (e) {
      debugPrint('❌ [ActivityRepository] Error getting today activities: $e');
      rethrow;
    }
  }

  /// 날짜 범위로 활동 조회
  Future<List<ActivityModel>> getActivitiesByDateRange(
    String familyId, {
    required DateTime startDate,
    required DateTime endDate,
    String? babyId,
    ActivityType? type,
  }) async {
    try {
      var query = SupabaseService.activities
          .select()
          .eq('family_id', familyId)
          .gte('start_time', startDate.toIso8601String())
          .lt('start_time', endDate.toIso8601String());

      if (babyId != null) {
        query = query.contains('baby_ids', [babyId]);
      }

      if (type != null) {
        query = query.eq('type', type.value);
      }

      final response = await query.order('start_time', ascending: false);

      return (response as List).map((data) => _mapToActivityModel(data)).toList();
    } catch (e) {
      debugPrint('❌ [ActivityRepository] Error getting activities by date: $e');
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
  Future<ActivityModel> finishActivity(String activityId, [DateTime? endTime]) async {
    try {
      final response = await SupabaseService.activities
          .update({'end_time': (endTime ?? DateTime.now()).toIso8601String()})
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

  // ========================================
  // Private Helpers
  // ========================================

  /// Supabase 응답 -> ActivityModel 변환
  ActivityModel _mapToActivityModel(Map<String, dynamic> data) {
    return ActivityModel(
      id: data['id'],
      familyId: data['family_id'],
      babyIds: List<String>.from(data['baby_ids'] as List),
      type: ActivityType.fromValue(data['type']),
      startTime: DateTime.parse(data['start_time']),
      endTime: data['end_time'] != null
          ? DateTime.parse(data['end_time'])
          : null,
      data: data['data'] as Map<String, dynamic>?,
      notes: data['notes'] as String?,
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : null,
    );
  }

  /// ActivityModel -> Supabase 데이터 변환
  Map<String, dynamic> _mapToSupabaseData(ActivityModel activity) {
    return {
      'id': activity.id,
      'family_id': activity.familyId,
      'baby_ids': activity.babyIds,
      'type': activity.type.value,
      'start_time': activity.startTime.toIso8601String(),
      if (activity.endTime != null) 'end_time': activity.endTime!.toIso8601String(),
      if (activity.data != null) 'data': activity.data,
      if (activity.notes != null) 'notes': activity.notes,
    };
  }
}
