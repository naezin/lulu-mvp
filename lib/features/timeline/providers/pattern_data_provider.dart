import 'package:flutter/foundation.dart';
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

  // Sprint 19 v5: DayTimeline 기반 데이터 (세로 스택 렌더링용)
  List<DayTimeline> _weekTimelines = [];
  List<List<DayTimeline>> _multipleWeekTimelines = []; // 다태아용

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

  // Sprint 19 v5: DayTimeline Getters
  List<DayTimeline> get weekTimelines => _weekTimelines;
  List<List<DayTimeline>> get multipleWeekTimelines => _multipleWeekTimelines;

  /// 주간 패턴 로드
  Future<void> loadWeeklyPattern({
    required String familyId,
    required String babyId,
    required String babyName,
    DateTime? weekStart,
  }) async {
    final targetWeekStart = weekStart ?? _weekStartDate;
    // Sprint 19: 캐시 비활성화 - 밤잠 자정 넘김 수정 반영 위해
    // final cacheKey = '$babyId-${targetWeekStart.toIso8601String()}';

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final weekEnd = targetWeekStart.add(const Duration(days: 7));

      // 전날 밤잠이 자정을 넘어 이어질 수 있으므로, 하루 전부터 조회
      final queryStart = targetWeekStart.subtract(const Duration(days: 1));

      final activities = await _activityRepository.getActivitiesByDateRange(
        familyId,
        startDate: queryStart,
        endDate: weekEnd,
      );

      // 아기 ID로 필터링
      final babyActivities = activities
          .where((a) => a.babyIds.contains(babyId))
          .toList();

      // WeeklyPattern 생성 (레거시 48-slot)
      final days = List.generate(7, (i) {
        final date = targetWeekStart.add(Duration(days: i));
        return _buildDailyPattern(date, babyActivities);
      });

      _weeklyPattern = WeeklyPattern(
        days: days,
        babyId: babyId,
        babyName: babyName,
      );

      // Sprint 19 v5: DayTimeline 생성 (세로 스택 렌더링용)
      _weekTimelines = List.generate(7, (i) {
        final date = targetWeekStart.add(Duration(days: i));
        return _buildDayTimeline(date, babyActivities);
      });

      _weekStartDate = targetWeekStart;

      // Sprint 19: 캐시 비활성화 (밤잠 자정 넘김 수정 테스트)
      // _cache[cacheKey] = _weeklyPattern!;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[PatternDataProvider] loadWeeklyPattern error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 이전 주로 이동
  Future<void> goToPreviousWeek({
    required String familyId,
    required String babyId,
    required String babyName,
  }) async {
    final newWeekStart = _weekStartDate.subtract(const Duration(days: 7));
    await loadWeeklyPattern(
      familyId: familyId,
      babyId: babyId,
      babyName: babyName,
      weekStart: newWeekStart,
    );
  }

  /// 다음 주로 이동
  Future<void> goToNextWeek({
    required String familyId,
    required String babyId,
    required String babyName,
  }) async {
    final newWeekStart = _weekStartDate.add(const Duration(days: 7));
    // 미래 주는 로드하지 않음
    if (newWeekStart.isAfter(DateTime.now())) return;

    await loadWeeklyPattern(
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

  /// Sprint 19 v5: DayTimeline 리스트 로드 (외부 호출용)
  Future<List<DayTimeline>> getWeekTimelines({
    required String familyId,
    required String babyId,
    DateTime? weekStart,
  }) async {
    final targetWeekStart = weekStart ?? _weekStartDate;
    final weekEnd = targetWeekStart.add(const Duration(days: 7));

    // 전날 밤잠이 자정을 넘어 이어질 수 있으므로, 하루 전부터 조회
    final queryStart = targetWeekStart.subtract(const Duration(days: 1));

    final activities = await _activityRepository.getActivitiesByDateRange(
      familyId,
      startDate: queryStart,
      endDate: weekEnd,
    );

    // 아기 ID로 필터링
    final babyActivities = activities
        .where((a) => a.babyIds.contains(babyId))
        .toList();

    // DayTimeline 생성
    return List.generate(7, (i) {
      final date = targetWeekStart.add(Duration(days: i));
      return _buildDayTimeline(date, babyActivities);
    });
  }

  /// Sprint 19 v5: 단일 날짜 DayTimeline 빌드 (비동기 - DB 호출)
  Future<DayTimeline> buildDayTimelineAsync({
    required String familyId,
    required String babyId,
    required DateTime date,
  }) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final activities = await _activityRepository.getActivitiesByDateRange(
      familyId,
      startDate: dayStart,
      endDate: dayEnd,
    );

    // 아기 ID로 필터링
    final babyActivities = activities
        .where((a) => a.babyIds.contains(babyId))
        .toList();

    return _buildDayTimeline(date, babyActivities);
  }

  /// Sprint 19 v5: 단일 날짜 DayTimeline 빌드 (동기 - 활동 리스트 전달)
  DayTimeline buildDayTimeline(DateTime date, List<ActivityModel> activities) {
    return _buildDayTimeline(date, activities);
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
      debugPrint('[PatternDataProvider] loadMultiplePatterns error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ActivityModel 리스트에서 DailyPattern 생성
  /// v4.1: 오버레이 지원 - 수면은 메인 활동, 나머지는 오버레이
  /// FIX-E: UTC -> Local 변환 추가
  DailyPattern _buildDailyPattern(DateTime date, List<ActivityModel> activities) {
    // 해당 날짜의 활동만 필터링 (로컬 시간 기준)
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final dayActivities = activities.where((a) {
      // FIX-E: UTC -> Local 변환
      final localStart = a.startTime.toLocal();
      return localStart.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
          localStart.isBefore(dayEnd);
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

      // v4.1: 주요 활동 (수면 우선) + 오버레이 수집
      PatternActivityType mainActivity = PatternActivityType.empty;
      String? mainActivityId;
      final overlays = <PatternActivityType>[];

      for (final activity in dayActivities) {
        // FIX-E: UTC -> Local 변환
        final actStart = activity.startTime.toLocal();
        final actEnd = (activity.endTime ?? activity.startTime.add(const Duration(hours: 1))).toLocal();

        if (actStart.isBefore(slotEnd) && actEnd.isAfter(slotStart)) {
          final patternType = _mapActivityType(activity.type, slotIndex ~/ 2);

          // 수면은 주요 활동으로
          if (patternType == PatternActivityType.nightSleep ||
              patternType == PatternActivityType.daySleep) {
            mainActivity = patternType;
            mainActivityId = activity.id;
          } else {
            // 나머지는 오버레이로
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
  PatternActivityType _mapActivityType(ActivityType type, int hour) {
    switch (type) {
      case ActivityType.sleep:
        // 밤잠/낮잠 판별에 SleepTimeConfig 사용
        return SleepTimeConfig.isNightTime(hour)
            ? PatternActivityType.nightSleep
            : PatternActivityType.daySleep;
      case ActivityType.feeding:
        return PatternActivityType.feeding;
      case ActivityType.diaper:
        return PatternActivityType.diaper;
      case ActivityType.play:
        return PatternActivityType.play; // v4.1: play 매핑
      case ActivityType.health:
        return PatternActivityType.health; // v4.1: health 매핑
    }
  }

  /// 주의 시작일 (월요일) 계산
  static DateTime _getWeekStart(DateTime date) {
    // 월요일이 주의 시작
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysFromMonday));
  }

  /// Sprint 19 v5: ActivityModel 리스트에서 DayTimeline 생성
  ///
  /// 모든 활동 → allBlocks에 추가 (세로 스택 렌더링용)
  /// Duration/Instant 구분 없이 전부 DurationBlock으로 변환
  DayTimeline _buildDayTimeline(DateTime date, List<ActivityModel> activities) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // 해당 날짜에 걸쳐있는 활동 필터링 (자정 넘김 포함)
    // 조건: (시작 < 날짜끝) AND (끝 > 날짜시작)
    final dayActivities = activities.where((a) {
      final localStart = a.startTime.toLocal();
      final localEnd = a.endTime?.toLocal() ?? localStart.add(const Duration(minutes: 5));
      // 활동이 해당 날짜와 겹치는지 확인
      return localStart.isBefore(dayEnd) && localEnd.isAfter(dayStart);
    }).toList();

    // allBlocks: 모든 활동을 DurationBlock으로 변환
    final allBlocks = <DurationBlock>[];
    // 레거시 분리 (통계 계산용)
    final durationBlocks = <DurationBlock>[];
    final instantMarkers = <InstantMarker>[];

    for (final activity in dayActivities) {
      final type = activity.type.name;
      final localStart = activity.startTime.toLocal();

      // endTime 결정
      DateTime localEnd;
      if (activity.endTime != null) {
        localEnd = activity.endTime!.toLocal();
      } else {
        // endTime 없으면 duration_minutes 사용, 없으면 기본 5분
        final durationMin = activity.data?['duration_minutes'] as int? ?? 5;
        localEnd = localStart.add(Duration(minutes: durationMin));
      }

      // subType 결정 (수면: night/nap, 놀이: play_type 등)
      String? subType;
      if (type == 'sleep') {
        // DB에서 sleep_type 읽기 (snake_case 또는 camelCase)
        subType = activity.data?['sleep_type'] as String? ??
            activity.data?['sleepType'] as String?;
        // 없으면 시간 기준 판별
        if (subType == null) {
          subType = SleepTimeConfig.isNightTime(localStart.hour) ? 'night' : 'nap';
        }
      } else if (type == 'play') {
        subType = activity.data?['play_type'] as String? ??
            activity.data?['playType'] as String?;
      }

      // DurationBlock 생성 (하루 경계로 클램핑)
      final block = DurationBlock(
        type: type,
        subType: subType,
        startTime: localStart,
        endTime: localEnd,
        activityId: activity.id,
      ).clampToDay(dayStart, dayEnd);

      // 디버그: 밤잠 자정 넘김 확인
      if (type == 'sleep' && localStart.day != date.day) {
        debugPrint('[DEBUG] 자정 넘김 수면: 원본 $localStart~$localEnd → clamp ${block.startTime}~${block.endTime} (date: $date)');
      }

      allBlocks.add(block);

      // 레거시 분리: 기저귀/건강 → InstantMarker, 나머지 → DurationBlock
      if (type == 'diaper' || type == 'health') {
        instantMarkers.add(InstantMarker(
          type: type,
          time: localStart,
          data: activity.data,
          activityId: activity.id,
        ));
      } else {
        durationBlocks.add(block);
      }
    }

    // 시작 시간순 정렬
    allBlocks.sort((a, b) => a.startTime.compareTo(b.startTime));
    durationBlocks.sort((a, b) => a.startTime.compareTo(b.startTime));
    instantMarkers.sort((a, b) => a.time.compareTo(b.time));

    return DayTimeline(
      date: date,
      allBlocks: allBlocks,
      durationBlocks: durationBlocks,
      instantMarkers: instantMarkers,
    );
  }
}
