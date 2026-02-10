import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/activity_model.dart';

/// 로컬 활동 저장 서비스
///
/// MVP-F: Supabase 인증 없이 로컬에서 활동 데이터 저장
/// 추후 인증 구현 시 Supabase와 동기화 가능
class LocalActivityService {
  static const String _keyActivities = 'local_activities';

  static final LocalActivityService _instance = LocalActivityService._internal();
  factory LocalActivityService() => _instance;
  LocalActivityService._internal();

  static LocalActivityService get instance => _instance;

  /// 활동 저장
  Future<ActivityModel> saveActivity(ActivityModel activity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activities = await loadAllActivities();

      // 새 활동 추가
      final updatedActivities = [...activities, activity];

      // JSON으로 저장
      final jsonList = updatedActivities.map((a) => a.toJson()).toList();
      await prefs.setString(_keyActivities, jsonEncode(jsonList));

      debugPrint('[OK] [LocalActivityService] Activity saved: ${activity.id}');
      return activity;
    } catch (e) {
      debugPrint('[ERR] [LocalActivityService] Save error: $e');
      rethrow;
    }
  }

  /// 모든 활동 로드
  Future<List<ActivityModel>> loadAllActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyActivities);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => ActivityModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ERR] [LocalActivityService] Load error: $e');
      return [];
    }
  }

  /// 가족 ID로 활동 조회
  Future<List<ActivityModel>> getActivitiesByFamilyId(String familyId) async {
    final activities = await loadAllActivities();
    return activities
        .where((a) => a.familyId == familyId)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// 아기 ID로 활동 조회
  Future<List<ActivityModel>> getActivitiesByBabyId(String babyId) async {
    final activities = await loadAllActivities();
    return activities
        .where((a) => a.babyIds.contains(babyId))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// 오늘의 활동 조회
  Future<List<ActivityModel>> getTodayActivities(String familyId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final activities = await getActivitiesByFamilyId(familyId);
    return activities
        .where((a) =>
            a.startTime.isAfter(startOfDay) &&
            a.startTime.isBefore(endOfDay))
        .toList();
  }

  /// 활동 삭제
  Future<void> deleteActivity(String activityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activities = await loadAllActivities();

      final updatedActivities = activities
          .where((a) => a.id != activityId)
          .toList();

      final jsonList = updatedActivities.map((a) => a.toJson()).toList();
      await prefs.setString(_keyActivities, jsonEncode(jsonList));

      debugPrint('[OK] [LocalActivityService] Activity deleted: $activityId');
    } catch (e) {
      debugPrint('[ERR] [LocalActivityService] Delete error: $e');
      rethrow;
    }
  }

  /// 활동 수정
  Future<ActivityModel> updateActivity(ActivityModel activity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activities = await loadAllActivities();

      final index = activities.indexWhere((a) => a.id == activity.id);
      if (index == -1) {
        throw Exception('Activity not found: ${activity.id}');
      }

      final updatedActivities = List<ActivityModel>.from(activities);
      updatedActivities[index] = activity;

      final jsonList = updatedActivities.map((a) => a.toJson()).toList();
      await prefs.setString(_keyActivities, jsonEncode(jsonList));

      debugPrint('[OK] [LocalActivityService] Activity updated: ${activity.id}');
      return activity;
    } catch (e) {
      debugPrint('[ERR] [LocalActivityService] Update error: $e');
      rethrow;
    }
  }

  /// 모든 활동 삭제 (리셋용)
  Future<void> clearAllActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyActivities);
      debugPrint('[OK] [LocalActivityService] All activities cleared');
    } catch (e) {
      debugPrint('[ERR] [LocalActivityService] Clear error: $e');
      rethrow;
    }
  }
}
