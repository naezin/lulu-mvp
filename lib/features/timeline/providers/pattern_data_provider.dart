import 'package:flutter/material.dart';

import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_type.dart';
import '../../../data/repositories/activity_repository.dart';
import '../models/daily_pattern.dart';

/// 주간 패턴 데이터 Provider
///
/// 작업 지시서 v1.1: PatternDataProvider
/// - ActivityModel → DailyPattern 변환
/// - 주간 데이터 로드/캐싱
/// - 필터 상태 관리
class PatternDataProvider extends ChangeNotifier {
  final ActivityRepository _activityRepository = ActivityRepository();

  // 상태
  WeeklyPattern? _weeklyPattern;
  List<WeeklyPattern> _multiplePatterns = []; // 다태아 함께보기용
  PatternFilter _filter = PatternFilter.all;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _weekStartDate = _getWeekStart(DateTime.now());
  bool _togetherViewEnabled = false;

  // 캐시
  final Map<String, WeeklyPattern> _cache = {};

  // Getters
  WeeklyPattern? get weeklyPattern => _weeklyPattern;
  List<WeeklyPattern> get multiplePatterns => _multiplePatterns;
  PatternFilter get filter => _filter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get weekStartDate => _weekStartDate;
  bool get togetherViewEnabled => _togetherViewEnabled;

  /// 주간 패턴 로드
  Future<void> loadWeeklyPattern({
    required String familyId,
    required String babyId,
    required String babyName,
    DateTime? weekStart,
  }) async {
    final targetWeekStart = weekStart ?? _weekStartDate;
    final cacheKey = '$babyId-${targetWeekStart.toIso8601String()}';

    // 캐시 확인
    if (_cache.containsKey(cacheKey)) {
      _weeklyPattern = _cache[cacheKey];
      _weekStartDate = targetWeekStart;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final weekEnd = targetWeekStart.add(const Duration(days: 7));

      final activities = await _activityRepository.getActivitiesByDateRange(
        familyId,
        startDate: targetWeekStart,
        endDate: weekEnd,
      );

      // 아기 ID로 필터링
      final babyActivities = activities
          .where((a) => a.babyIds.contains(babyId))
          .toList();

      // WeeklyPattern 생성
      final days = List.generate(7, (i) {
        final date = targetWeekStart.add(Duration(days: i));
        return _buildDailyPattern(date, babyActivities);
      });

      _weeklyPattern = WeeklyPattern(
        days: days,
        babyId: babyId,
        babyName: babyName,
      );

      _weekStartDate = targetWeekStart;

      // 캐시 저장
      _cache[cacheKey] = _weeklyPattern!;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '패턴 데이터 로드 실패: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 이전 주로 이동
  void goToPreviousWeek({
    required String familyId,
    required String babyId,
    required String babyName,
  }) {
    final newWeekStart = _weekStartDate.subtract(const Duration(days: 7));
    loadWeeklyPattern(
      familyId: familyId,
      babyId: babyId,
      babyName: babyName,
      weekStart: newWeekStart,
    );
  }

  /// 다음 주로 이동
  void goToNextWeek({
    required String familyId,
    required String babyId,
    required String babyName,
  }) {
    final newWeekStart = _weekStartDate.add(const Duration(days: 7));
    // 미래 주는 로드하지 않음
    if (newWeekStart.isAfter(DateTime.now())) return;

    loadWeeklyPattern(
      familyId: familyId,
      babyId: babyId,
      babyName: babyName,
      weekStart: newWeekStart,
    );
  }

  /// 필터 변경
  void setFilter(PatternFilter newFilter) {
    if (_filter == newFilter) return;
    _filter = newFilter;
    notifyListeners();
  }

  /// 캐시 초기화
  void clearCache() {
    _cache.clear();
  }

  /// 다태아 함께보기 토글
  void toggleTogetherView() {
    _togetherViewEnabled = !_togetherViewEnabled;
    notifyListeners();
  }

  /// 다태아 함께보기 활성화/비활성화
  void setTogetherView(bool enabled) {
    if (_togetherViewEnabled == enabled) return;
    _togetherViewEnabled = enabled;
    notifyListeners();
  }

  /// 다태아 패턴 로드 (함께보기용)
  Future<void> loadMultiplePatterns({
    required String familyId,
    required List<String> babyIds,
    required List<String> babyNames,
    DateTime? weekStart,
  }) async {
    if (babyIds.length != babyNames.length) return;

    final targetWeekStart = weekStart ?? _weekStartDate;

    // 캐시 확인 - 개별 패턴들이 모두 캐시에 있는지 확인
    final cachedPatterns = <WeeklyPattern>[];
    bool allCached = true;

    for (int i = 0; i < babyIds.length; i++) {
      final cacheKey = '${babyIds[i]}-${targetWeekStart.toIso8601String()}';
      if (_cache.containsKey(cacheKey)) {
        cachedPatterns.add(_cache[cacheKey]!);
      } else {
        allCached = false;
        break;
      }
    }

    if (allCached && cachedPatterns.length == babyIds.length) {
      _multiplePatterns = cachedPatterns;
      _weekStartDate = targetWeekStart;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final weekEnd = targetWeekStart.add(const Duration(days: 7));

      final activities = await _activityRepository.getActivitiesByDateRange(
        familyId,
        startDate: targetWeekStart,
        endDate: weekEnd,
      );

      _multiplePatterns = [];

      for (int i = 0; i < babyIds.length; i++) {
        final babyId = babyIds[i];
        final babyName = babyNames[i];
        final cacheKey = '$babyId-${targetWeekStart.toIso8601String()}';

        // 개별 캐시 확인
        if (_cache.containsKey(cacheKey)) {
          _multiplePatterns.add(_cache[cacheKey]!);
          continue;
        }

        // 아기 ID로 필터링
        final babyActivities = activities
            .where((a) => a.babyIds.contains(babyId))
            .toList();

        // WeeklyPattern 생성
        final days = List.generate(7, (j) {
          final date = targetWeekStart.add(Duration(days: j));
          return _buildDailyPattern(date, babyActivities);
        });

        final pattern = WeeklyPattern(
          days: days,
          babyId: babyId,
          babyName: babyName,
        );

        _multiplePatterns.add(pattern);

        // 개별 캐시 저장
        _cache[cacheKey] = pattern;
      }

      _weekStartDate = targetWeekStart;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '패턴 데이터 로드 실패: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ActivityModel 리스트에서 DailyPattern 생성
  DailyPattern _buildDailyPattern(DateTime date, List<ActivityModel> activities) {
    // 해당 날짜의 활동만 필터링
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final dayActivities = activities.where((a) {
      return a.startTime.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
          a.startTime.isBefore(dayEnd);
    }).toList();

    // 48개 슬롯 생성
    final slots = List.generate(48, (slotIndex) {
      final slotStart = DateTime(
        date.year,
        date.month,
        date.day,
        slotIndex ~/ 2,
        (slotIndex % 2) * 30,
      );
      final slotEnd = slotStart.add(const Duration(minutes: 30));

      // 슬롯에 해당하는 활동 찾기
      for (final activity in dayActivities) {
        final actEnd = activity.endTime ??
            activity.startTime.add(const Duration(hours: 1));

        if (activity.startTime.isBefore(slotEnd) && actEnd.isAfter(slotStart)) {
          return TimeSlot(
            hour: slotIndex ~/ 2,
            halfHour: slotIndex % 2,
            activity: _mapActivityType(activity.type, slotIndex ~/ 2),
            activityId: activity.id,
          );
        }
      }

      return TimeSlot(
        hour: slotIndex ~/ 2,
        halfHour: slotIndex % 2,
        activity: PatternActivityType.empty,
      );
    });

    return DailyPattern(date: date, slots: slots);
  }

  /// ActivityType을 PatternActivityType으로 변환
  PatternActivityType _mapActivityType(ActivityType type, int hour) {
    switch (type) {
      case ActivityType.sleep:
        // 밤잠: 21:00-06:00, 낮잠: 06:00-21:00
        return (hour >= 21 || hour < 6)
            ? PatternActivityType.nightSleep
            : PatternActivityType.daySleep;
      case ActivityType.feeding:
        return PatternActivityType.feeding;
      case ActivityType.diaper:
        return PatternActivityType.diaper;
      case ActivityType.play:
      case ActivityType.health:
        return PatternActivityType.empty;
    }
  }

  /// 주의 시작일 (월요일) 계산
  static DateTime _getWeekStart(DateTime date) {
    // 월요일이 주의 시작
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysFromMonday));
  }
}
