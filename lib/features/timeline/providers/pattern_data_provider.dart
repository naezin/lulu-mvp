import 'package:flutter/material.dart';

import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_type.dart';
import '../../../data/repositories/activity_repository.dart';
import '../models/daily_pattern.dart';
import '../models/day_timeline.dart';

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

  // v4.1: 멀티 필터 상태 (Set 방식)
  Set<PatternActivityType> _activeFilters = {
    PatternActivityType.nightSleep,
    PatternActivityType.daySleep,
    PatternActivityType.feeding,
    PatternActivityType.diaper,
  };

  // 캐시
  final Map<String, WeeklyPattern> _cache = {};

  // Getters
  WeeklyPattern? get weeklyPattern => _weeklyPattern;
  List<WeeklyPattern> get multiplePatterns => _multiplePatterns;
  PatternFilter get filter => _filter;
  Set<PatternActivityType> get activeFilters => _activeFilters; // v4.1 추가
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

      debugPrint('[DEBUG] [PatternProvider] Loaded ${babyActivities.length} activities for $babyName');

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
  /// HF3-FIX: 캐시 무효화 옵션 추가
  void goToPreviousWeek({
    required String familyId,
    required String babyId,
    required String babyName,
    bool forceRefresh = false,
  }) {
    final newWeekStart = _weekStartDate.subtract(const Duration(days: 7));

    // HF3-FIX: forceRefresh 시 캐시 제거
    if (forceRefresh) {
      final cacheKey = '$babyId-${newWeekStart.toIso8601String()}';
      _cache.remove(cacheKey);
    }

    loadWeeklyPattern(
      familyId: familyId,
      babyId: babyId,
      babyName: babyName,
      weekStart: newWeekStart,
    );
  }

  /// 다음 주로 이동
  /// HF3-FIX: 캐시 무효화 옵션 추가
  void goToNextWeek({
    required String familyId,
    required String babyId,
    required String babyName,
    bool forceRefresh = false,
  }) {
    final newWeekStart = _weekStartDate.add(const Duration(days: 7));
    // 미래 주는 로드하지 않음
    if (newWeekStart.isAfter(DateTime.now())) return;

    // HF3-FIX: forceRefresh 시 캐시 제거
    if (forceRefresh) {
      final cacheKey = '$babyId-${newWeekStart.toIso8601String()}';
      _cache.remove(cacheKey);
    }

    loadWeeklyPattern(
      familyId: familyId,
      babyId: babyId,
      babyName: babyName,
      weekStart: newWeekStart,
    );
  }

  /// 필터 변경 (기존 호환용)
  void setFilter(PatternFilter newFilter) {
    if (_filter == newFilter) return;
    _filter = newFilter;
    notifyListeners();
  }

  /// v4.1: 멀티 필터 설정
  void setActiveFilters(Set<PatternActivityType> filters) {
    _activeFilters = filters;
    notifyListeners();
  }

  /// v4.1: 필터 토글
  void toggleFilter(PatternActivityType type) {
    final newFilters = Set<PatternActivityType>.from(_activeFilters);

    // sleep 토글 시 night + day 함께
    if (type == PatternActivityType.nightSleep ||
        type == PatternActivityType.daySleep) {
      final hasSleep = newFilters.contains(PatternActivityType.nightSleep);
      if (hasSleep) {
        newFilters.remove(PatternActivityType.nightSleep);
        newFilters.remove(PatternActivityType.daySleep);
      } else {
        newFilters.add(PatternActivityType.nightSleep);
        newFilters.add(PatternActivityType.daySleep);
      }
    } else {
      if (newFilters.contains(type)) {
        newFilters.remove(type);
      } else {
        newFilters.add(type);
      }
    }

    _activeFilters = newFilters;
    notifyListeners();
  }

  /// 캐시 초기화
  void clearCache() {
    _cache.clear();
  }

  /// HF7-FIX: 특정 캐시 키 무효화
  void invalidateCacheKey(String cacheKey) {
    _cache.remove(cacheKey);
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
  /// HF8-FIX: Duration 활동 클램핑 + 디버그 로그
  DailyPattern _buildDailyPattern(DateTime date, List<ActivityModel> activities) {
    // 해당 날짜의 활동만 필터링 (로컬 시간 기준)
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final dayActivities = activities.where((a) {
      final localStart = a.startTime.toLocal();
      final localEnd = a.endTime?.toLocal();

      if (localEnd != null) {
        // Duration 활동: 해당 날짜와 겹치는지 확인
        return localStart.isBefore(dayEnd) && localEnd.isAfter(dayStart);
      } else {
        // Instant 활동: 시작 시간이 해당 날짜인지 확인
        return !localStart.isBefore(dayStart) && localStart.isBefore(dayEnd);
      }
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

      PatternActivityType mainActivity = PatternActivityType.empty;
      String? mainActivityId;
      final overlays = <PatternActivityType>[];

      for (final activity in dayActivities) {
        final actStart = activity.startTime.toLocal();

        // HF8-FIX: Duration vs Instant 활동 분리 처리
        bool overlapsSlot = false;

        if (activity.endTime != null) {
          // Duration 활동 (수면/놀이): 해당 날짜 범위로 클램핑 후 슬롯 비교
          final actEnd = activity.endTime!.toLocal();
          final clampedStart = actStart.isBefore(dayStart) ? dayStart : actStart;
          final clampedEnd = actEnd.isAfter(dayEnd) ? dayEnd : actEnd;
          overlapsSlot = clampedStart.isBefore(slotEnd) && clampedEnd.isAfter(slotStart);
        } else {
          // Instant 활동 (수유/기저귀/건강): 1분 폭으로 슬롯 비교
          final actEnd = actStart.add(const Duration(minutes: 1));
          overlapsSlot = actStart.isBefore(slotEnd) && actEnd.isAfter(slotStart);
        }

        if (overlapsSlot) {
          final patternType = _mapActivityType(activity.type, slotIndex ~/ 2, activity.data);

          // 우선순위 기반 mainActivity 설정 (수면 > 수유 > 기저귀 > 놀이 > 건강)
          if (patternType == PatternActivityType.nightSleep ||
              patternType == PatternActivityType.daySleep) {
            mainActivity = patternType;
            mainActivityId = activity.id;
          } else if (mainActivity == PatternActivityType.empty) {
            mainActivity = patternType;
            mainActivityId = activity.id;
          } else if (mainActivity != PatternActivityType.nightSleep &&
                     mainActivity != PatternActivityType.daySleep) {
            final currentPriority = _getActivityPriority(mainActivity);
            final newPriority = _getActivityPriority(patternType);
            if (newPriority < currentPriority) {
              if (!overlays.contains(mainActivity)) {
                overlays.add(mainActivity);
              }
              mainActivity = patternType;
              mainActivityId = activity.id;
            } else {
              if (!overlays.contains(patternType)) {
                overlays.add(patternType);
              }
            }
          } else {
            // 수면이 mainActivity면 다른 활동은 오버레이로
            if (!overlays.contains(patternType)) {
              overlays.add(patternType);
            }
          }
        }
      }

      return TimeSlot(
        hour: slotIndex ~/ 2,
        halfHour: slotIndex % 2,
        activity: mainActivity,
        activityId: mainActivityId,
        overlays: overlays,
      );
    });

    return DailyPattern(date: date, slots: slots);
  }

  /// ActivityType을 PatternActivityType으로 변환
  /// HF2-8: DB의 sleep_type 값 우선 사용, 없으면 시간 기반 fallback
  PatternActivityType _mapActivityType(ActivityType type, int hour, Map<String, dynamic>? data) {
    switch (type) {
      case ActivityType.sleep:
        // HF2-8: DB의 sleep_type 값 우선 확인
        final sleepType = data?['sleep_type'] as String?;
        if (sleepType == 'night') {
          return PatternActivityType.nightSleep;
        } else if (sleepType == 'nap') {
          return PatternActivityType.daySleep;
        }
        // fallback: 시간 기반 판별 (DB값 없을 때만)
        return SleepTimeConfig.isNightTime(hour)
            ? PatternActivityType.nightSleep
            : PatternActivityType.daySleep;
      case ActivityType.feeding:
        return PatternActivityType.feeding;
      case ActivityType.diaper:
        return PatternActivityType.diaper;
      case ActivityType.play:
        return PatternActivityType.play;
      case ActivityType.health:
        return PatternActivityType.health;
    }
  }

  /// 활동 우선순위 반환 (낮을수록 높은 우선순위)
  /// HF3-FIX: 수면 > 수유 > 기저귀 > 놀이 > 건강
  int _getActivityPriority(PatternActivityType type) {
    switch (type) {
      case PatternActivityType.nightSleep:
      case PatternActivityType.daySleep:
        return 0; // 최고 우선순위
      case PatternActivityType.feeding:
        return 1;
      case PatternActivityType.diaper:
        return 2;
      case PatternActivityType.play:
        return 3;
      case PatternActivityType.health:
        return 4;
      case PatternActivityType.empty:
        return 99;
    }
  }

  /// 주의 시작일 (월요일) 계산
  static DateTime _getWeekStart(DateTime date) {
    // 월요일이 주의 시작
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysFromMonday));
  }

  // ========================================
  // Sprint 19: DayTimeline 기반 메서드 (실제 시간)
  // DailyGrid, WeeklyChartFull용
  // ========================================

  /// ActivityModel 리스트에서 DayTimeline 생성 (실제 시간 기반)
  /// overnight clamping 적용: 자정 넘기는 활동은 해당 날짜로 클램핑
  DayTimeline buildDayTimeline(DateTime date, List<ActivityModel> activities) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final durationBlocks = <DurationBlock>[];
    final instantMarkers = <InstantMarker>[];

    for (final activity in activities) {
      final localStart = activity.startTime.toLocal();
      final localEnd = activity.endTime?.toLocal();

      // Duration 활동 (수면, 놀이)
      if (localEnd != null) {
        // 해당 날짜와 겹치는지 확인
        if (localStart.isBefore(dayEnd) && localEnd.isAfter(dayStart)) {
          // overnight clamping: 해당 날짜 범위로 클램핑
          final clampedStart = localStart.isBefore(dayStart) ? dayStart : localStart;
          final clampedEnd = localEnd.isAfter(dayEnd) ? dayEnd : localEnd;

          // 유효한 블록인지 확인 (최소 1분)
          if (clampedEnd.isAfter(clampedStart)) {
            final type = _mapToDurationBlockType(activity.type, activity.data);
            durationBlocks.add(DurationBlock(
              type: type,
              startTime: clampedStart,
              endTime: clampedEnd,
              activityId: activity.id,
            ));
          }
        }
      }
      // Instant 활동 (수유, 기저귀, 건강)
      else {
        // 해당 날짜에 속하는지 확인
        if (!localStart.isBefore(dayStart) && localStart.isBefore(dayEnd)) {
          final type = _mapToInstantMarkerType(activity.type);
          instantMarkers.add(InstantMarker(
            type: type,
            time: localStart,
            data: activity.data,
            activityId: activity.id,
          ));
        }
      }
    }

    return DayTimeline(
      date: date,
      durationBlocks: durationBlocks,
      instantMarkers: instantMarkers,
    );
  }

  /// 7일분 DayTimeline 생성
  List<DayTimeline> buildWeekTimelines(
    DateTime weekStart,
    List<ActivityModel> activities,
  ) {
    return List.generate(7, (i) {
      final date = weekStart.add(Duration(days: i));
      return buildDayTimeline(date, activities);
    });
  }

  /// 주간 요약 계산 (트렌드 포함)
  WeeklySummary buildWeeklySummary(List<DayTimeline> timelines) {
    if (timelines.isEmpty) return WeeklySummary.empty();

    final daysWithData = timelines.where((t) => t.hasData).toList();
    if (daysWithData.isEmpty) return WeeklySummary.empty();

    final dayCount = daysWithData.length;

    // 평균 계산
    final totalSleep = daysWithData.fold(0.0, (sum, t) => sum + t.totalSleepHours);
    final totalFeedGap = daysWithData.fold(0.0, (sum, t) => sum + t.avgFeedingGap);
    final totalFeedCount = daysWithData.fold(0, (sum, t) => sum + t.feedingCount);
    final totalDiapers = daysWithData.fold(0, (sum, t) => sum + t.diaperCount);
    final totalPlay = daysWithData.fold(0, (sum, t) => sum + t.playMinutes);

    // 수유 간격은 데이터 있는 날만 평균
    final daysWithFeedings = daysWithData.where((t) => t.feedingCount >= 2).length;
    final avgFeedGap = daysWithFeedings > 0
        ? totalFeedGap / daysWithFeedings
        : 0.0;

    // 트렌드 계산 (주 초반 3일 vs 주 후반 3일)
    double sleepTrend = 0;
    double feedGapTrend = 0;

    if (timelines.length >= 6) {
      final firstHalf = timelines.sublist(0, 3);
      final secondHalf = timelines.sublist(4, 7);

      final firstHalfSleep = firstHalf
          .where((t) => t.hasData)
          .fold(0.0, (sum, t) => sum + t.totalSleepHours);
      final secondHalfSleep = secondHalf
          .where((t) => t.hasData)
          .fold(0.0, (sum, t) => sum + t.totalSleepHours);

      final firstCount = firstHalf.where((t) => t.hasData).length;
      final secondCount = secondHalf.where((t) => t.hasData).length;

      if (firstCount > 0 && secondCount > 0) {
        sleepTrend = (secondHalfSleep / secondCount) - (firstHalfSleep / firstCount);
      }

      // 수유 간격 트렌드
      final firstHalfGap = firstHalf
          .where((t) => t.feedingCount >= 2)
          .fold(0.0, (sum, t) => sum + t.avgFeedingGap);
      final secondHalfGap = secondHalf
          .where((t) => t.feedingCount >= 2)
          .fold(0.0, (sum, t) => sum + t.avgFeedingGap);

      final firstGapCount = firstHalf.where((t) => t.feedingCount >= 2).length;
      final secondGapCount = secondHalf.where((t) => t.feedingCount >= 2).length;

      if (firstGapCount > 0 && secondGapCount > 0) {
        feedGapTrend = (secondHalfGap / secondGapCount) - (firstHalfGap / firstGapCount);
      }
    }

    // 밤잠 시작 시간 평균
    double? avgNightSleepStart;
    final nightSleepStarts = <double>[];
    for (final t in daysWithData) {
      for (final block in t.durationBlocks) {
        if (block.type == 'nightSleep') {
          final hour = block.startHour;
          // 밤 시간 (18시 이후)에 시작한 것만
          if (hour >= 18 || hour < 6) {
            nightSleepStarts.add(hour >= 18 ? hour : hour + 24);
          }
        }
      }
    }
    if (nightSleepStarts.isNotEmpty) {
      final avg = nightSleepStarts.reduce((a, b) => a + b) / nightSleepStarts.length;
      avgNightSleepStart = avg > 24 ? avg - 24 : avg;
    }

    return WeeklySummary(
      avgSleepHours: totalSleep / dayCount,
      avgFeedGap: avgFeedGap,
      avgFeedCount: (totalFeedCount / dayCount).round(),
      avgDiapers: totalDiapers / dayCount,
      avgPlayMinutes: totalPlay / dayCount,
      sleepTrend: sleepTrend,
      feedGapTrend: feedGapTrend,
      avgNightSleepStartHour: avgNightSleepStart,
    );
  }

  /// ActivityType -> DurationBlock type 변환
  String _mapToDurationBlockType(ActivityType type, Map<String, dynamic>? data) {
    switch (type) {
      case ActivityType.sleep:
        final sleepType = data?['sleep_type'] as String?;
        if (sleepType == 'night') return 'nightSleep';
        if (sleepType == 'nap') return 'daySleep';
        // fallback: 시간 기반
        return 'daySleep';
      case ActivityType.play:
        return 'play';
      default:
        return 'play'; // 기타 Duration은 play로 분류
    }
  }

  /// ActivityType -> InstantMarker type 변환
  String _mapToInstantMarkerType(ActivityType type) {
    switch (type) {
      case ActivityType.feeding:
        return 'feeding';
      case ActivityType.diaper:
        return 'diaper';
      case ActivityType.health:
        return 'health';
      default:
        return 'health'; // 기타 Instant은 health로 분류
    }
  }
}
