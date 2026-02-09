import 'package:flutter/foundation.dart';

import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_type.dart';
import '../../../data/models/feeding_type.dart';
import '../../../data/repositories/activity_repository.dart';
import '../models/weekly_statistics.dart';
import '../models/together_data.dart';
import '../models/insight_data.dart';
import 'statistics_filter_provider.dart';

/// 캐시 엔트리 (TTL 지원)
class _CacheEntry {
  final WeeklyStatistics data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();

  /// 5분 후 만료
  bool get isExpired =>
      DateTime.now().difference(timestamp).inMinutes > 5;
}

/// 통계 데이터 Provider
///
/// 작업 지시서 v1.2.1: 데이터 fetching + 캐싱
/// Provider 분리: 데이터 변경 시 → 차트만 리빌드
class StatisticsDataProvider extends ChangeNotifier {
  final ActivityRepository _activityRepository = ActivityRepository();

  /// 캐시된 통계 데이터 (TTL 5분)
  final Map<String, _CacheEntry> _cache = {};

  /// 현재 표시 중인 통계
  WeeklyStatistics? _currentStatistics;

  /// 함께 보기 데이터
  TogetherData? _togetherData;

  /// AI 인사이트
  InsightData? _insight;

  /// 마지막 동기화 시간
  DateTime? _lastSyncTime;

  /// 오프라인 모드 여부
  bool _isOffline = false;

  // Getters
  WeeklyStatistics? get currentStatistics => _currentStatistics;
  TogetherData? get togetherData => _togetherData;
  InsightData? get insight => _insight;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isOffline => _isOffline;
  bool get hasData => _currentStatistics != null;

  /// 통계 데이터 로드
  Future<void> loadStatistics({
    required String familyId,
    required String? babyId,
    required DateRange dateRange,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _buildCacheKey(babyId, dateRange);

    // 캐시 확인 (TTL 5분)
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (!entry.isExpired) {
        _currentStatistics = entry.data;
        _generateInsight();
        notifyListeners();
        return;
      }
    }

    try {
      // Supabase에서 데이터 로드
      final statistics = await _fetchStatisticsFromSupabase(
        familyId: familyId,
        babyId: babyId,
        dateRange: dateRange,
      );

      _cache[cacheKey] = _CacheEntry(statistics);
      _currentStatistics = statistics;
      _lastSyncTime = DateTime.now();
      _isOffline = false;

      _generateInsight();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [StatisticsDataProvider] Load error: $e');
      // 오프라인이거나 에러 발생 시 캐시 데이터 사용
      if (_cache.containsKey(cacheKey)) {
        _currentStatistics = _cache[cacheKey]!.data;
        _isOffline = true;
        notifyListeners();
      } else {
        rethrow;
      }
    }
  }

  /// 함께 보기 데이터 로드
  Future<void> loadTogetherData({
    required String familyId,
    required List<BabyInfo> babies,
    required DateRange dateRange,
  }) async {
    try {
      final babySummaries = <BabyStatisticsSummary>[];

      for (final baby in babies) {
        final statistics = await _fetchStatisticsFromSupabase(
          familyId: familyId,
          babyId: baby.id,
          dateRange: dateRange,
        );

        babySummaries.add(BabyStatisticsSummary(
          babyId: baby.id,
          babyName: baby.name,
          correctedAgeDays: baby.correctedAgeDays,
          statistics: statistics,
        ));
      }

      _togetherData = TogetherData(
        babies: babySummaries,
        startDate: dateRange.start,
        endDate: dateRange.end,
      );
      _lastSyncTime = DateTime.now();
      _isOffline = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [StatisticsDataProvider] Together data error: $e');
      rethrow;
    }
  }

  /// 캐시 무효화 (아기 추가/삭제 시)
  void invalidateCache() {
    _cache.clear();
    _currentStatistics = null;
    _togetherData = null;
    _insight = null;
    notifyListeners();
  }

  /// 특정 기간 캐시 무효화 (기록 수정/삭제 시)
  void invalidateCacheForDate(DateTime date) {
    // 해당 날짜가 포함된 모든 캐시 키 제거
    _cache.removeWhere((key, entry) {
      return date.isAfter(entry.data.startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(entry.data.endDate.add(const Duration(days: 1)));
    });
    notifyListeners();
  }

  /// 오프라인 상태 설정
  void setOfflineMode(bool offline) {
    if (_isOffline != offline) {
      _isOffline = offline;
      notifyListeners();
    }
  }

  /// 캐시 키 생성
  String _buildCacheKey(String? babyId, DateRange dateRange) {
    final babyPart = babyId ?? 'all';
    final startPart = dateRange.start.toIso8601String().split('T')[0];
    final endPart = dateRange.end.toIso8601String().split('T')[0];
    return '${babyPart}_${startPart}_$endPart';
  }

  /// AI 인사이트 생성
  void _generateInsight() {
    if (_currentStatistics == null) {
      _insight = null;
      return;
    }

    final sleep = _currentStatistics!.sleep;

    // 가장 수면이 많은 요일 찾기
    int maxDayIndex = 0;
    double maxHours = 0;
    for (int i = 0; i < sleep.dailyHours.length; i++) {
      if (sleep.dailyHours[i] > maxHours) {
        maxHours = sleep.dailyHours[i];
        maxDayIndex = i;
      }
    }

    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    // 인사이트 메시지 생성
    String message;
    InsightType type;

    if (sleep.changeMinutes > 30) {
      message = 'insight_sleep_increased';
      type = InsightType.positive;
    } else if (sleep.changeMinutes < -30) {
      message = 'insight_sleep_decreased';
      type = InsightType.attention;
    } else if (maxHours > 0) {
      message = 'insight_most_sleep_day:${dayNames[maxDayIndex]}';
      type = InsightType.neutral;
    } else {
      message = 'insight_start_recording';
      type = InsightType.neutral;
    }

    _insight = InsightData(
      message: message,
      type: type,
      relatedReportType: 'sleep',
      highlightDayIndex: maxHours > 0 ? maxDayIndex : null,
    );
  }

  /// Supabase에서 통계 데이터 가져오기
  Future<WeeklyStatistics> _fetchStatisticsFromSupabase({
    required String familyId,
    required String? babyId,
    required DateRange dateRange,
  }) async {
    debugPrint('[DEBUG] [StatisticsDataProvider] Fetching: familyId=$familyId, babyId=$babyId');
    debugPrint('[DEBUG] [StatisticsDataProvider] DateRange: ${dateRange.start} ~ ${dateRange.end}');

    // 이번 주 데이터
    final activities = await _activityRepository.getActivitiesByDateRange(
      familyId,
      startDate: dateRange.start,
      endDate: dateRange.end.add(const Duration(days: 1)), // 종료일 포함
      babyId: babyId,
    );

    debugPrint('[DEBUG] [StatisticsDataProvider] Found ${activities.length} activities this week');

    // 지난 주 데이터 (변화량 계산용)
    final lastWeekStart = dateRange.start.subtract(const Duration(days: 7));
    final lastWeekEnd = dateRange.start.subtract(const Duration(days: 1));
    final lastWeekActivities = await _activityRepository.getActivitiesByDateRange(
      familyId,
      startDate: lastWeekStart,
      endDate: lastWeekEnd.add(const Duration(days: 1)),
      babyId: babyId,
    );

    debugPrint('[DEBUG] [StatisticsDataProvider] Found ${lastWeekActivities.length} activities last week');

    // 통계 계산
    final sleepStats = _calculateSleepStatistics(
      activities,
      lastWeekActivities,
      dateRange,
    );
    final feedingStats = _calculateFeedingStatistics(
      activities,
      lastWeekActivities,
      dateRange,
    );
    final diaperStats = _calculateDiaperStatistics(
      activities,
      lastWeekActivities,
      dateRange,
    );

    return WeeklyStatistics(
      sleep: sleepStats,
      feeding: feedingStats,
      diaper: diaperStats,
      startDate: dateRange.start,
      endDate: dateRange.end,
    );
  }

  /// 수면 통계 계산
  SleepStatistics _calculateSleepStatistics(
    List<ActivityModel> activities,
    List<ActivityModel> lastWeekActivities,
    DateRange dateRange,
  ) {
    final sleepActivities = activities
        .where((a) => a.type == ActivityType.sleep && a.endTime != null)
        .toList();
    final lastWeekSleep = lastWeekActivities
        .where((a) => a.type == ActivityType.sleep && a.endTime != null)
        .toList();

    // 요일별 수면 시간 (월~일)
    final dailyHours = List.filled(7, 0.0);
    int napMinutes = 0;
    int nightMinutes = 0;
    int nightWakeups = 0;

    for (final activity in sleepActivities) {
      final duration = activity.durationMinutes ?? 0;
      final dayIndex = (activity.startTime.weekday - 1) % 7;
      dailyHours[dayIndex] += duration / 60.0;

      // 낮잠/밤잠 구분 (6시~20시: 낮잠)
      final hour = activity.startTime.hour;
      if (hour >= 6 && hour < 20) {
        napMinutes += duration;
      } else {
        nightMinutes += duration;
        // 야간 기상 카운트 (밤잠 시작 후 다시 잠든 경우)
        if (hour >= 0 && hour < 6) {
          nightWakeups++;
        }
      }
    }

    final totalMinutes = napMinutes + nightMinutes;
    final dayCount = dateRange.dayCount > 0 ? dateRange.dayCount : 1;
    final dailyAverage = totalMinutes / 60.0 / dayCount;

    // 지난 주 평균
    int lastWeekTotal = 0;
    for (final activity in lastWeekSleep) {
      lastWeekTotal += activity.durationMinutes ?? 0;
    }
    final lastWeekDailyAverage = lastWeekTotal / 60.0 / 7;
    final changeMinutes = ((dailyAverage - lastWeekDailyAverage) * 60).round();

    return SleepStatistics(
      dailyAverageHours: dailyAverage,
      changeMinutes: changeMinutes,
      dailyHours: dailyHours,
      napRatio: totalMinutes > 0 ? napMinutes / totalMinutes : 0,
      nightRatio: totalMinutes > 0 ? nightMinutes / totalMinutes : 0,
      nightWakeups: nightWakeups,
    );
  }

  /// 수유 통계 계산
  /// 🔧 Sprint 19 E: ml 통계 추가
  FeedingStatistics _calculateFeedingStatistics(
    List<ActivityModel> activities,
    List<ActivityModel> lastWeekActivities,
    DateRange dateRange,
  ) {
    final feedingActivities = activities
        .where((a) => a.type == ActivityType.feeding)
        .toList();
    final lastWeekFeeding = lastWeekActivities
        .where((a) => a.type == ActivityType.feeding)
        .toList();

    // 요일별 수유 횟수 (월~일)
    final dailyCounts = List.filled(7, 0);
    int breastCount = 0;
    int formulaCount = 0;
    int solidCount = 0;

    // 🔧 Sprint 19 E: ml 합계 계산
    double totalMl = 0;

    for (final activity in feedingActivities) {
      final dayIndex = (activity.startTime.weekday - 1) % 7;
      dailyCounts[dayIndex]++;

      // 🔧 Sprint 19 E: ml 데이터 합산
      final ml = activity.feedingAmountMl;
      if (ml != null && ml > 0) {
        totalMl += ml;
      }

      // 수유 타입별 카운트
      final contentType = activity.feedingContentType;
      if (contentType != null) {
        switch (contentType) {
          case FeedingContentType.breastMilk:
            breastCount++;
          case FeedingContentType.formula:
            formulaCount++;
          case FeedingContentType.solid:
            solidCount++;
        }
      } else {
        // 레거시 데이터 지원
        final feedingType = activity.feedingType;
        if (feedingType == 'breast' || feedingType == 'breast_milk') {
          breastCount++;
        } else if (feedingType == 'formula' || feedingType == 'bottle') {
          formulaCount++;
        } else if (feedingType == 'solid') {
          solidCount++;
        }
      }
    }

    final totalCount = feedingActivities.length;
    final dayCount = dateRange.dayCount > 0 ? dateRange.dayCount : 1;
    final dailyAverage = totalCount / dayCount;

    // 🔧 Sprint 19 E: 일평균 ml 계산
    final dailyAverageMl = totalMl / dayCount;

    // 지난 주 대비 변화
    final lastWeekDailyAverage = lastWeekFeeding.length / 7;
    final changeCount = (dailyAverage - lastWeekDailyAverage).round();

    return FeedingStatistics(
      dailyAverageCount: dailyAverage,
      dailyAverageMl: dailyAverageMl,
      changeCount: changeCount,
      dailyCounts: dailyCounts,
      breastMilkRatio: totalCount > 0 ? breastCount / totalCount : 0,
      formulaRatio: totalCount > 0 ? formulaCount / totalCount : 0,
      solidFoodRatio: totalCount > 0 ? solidCount / totalCount : 0,
    );
  }

  /// 기저귀 통계 계산
  DiaperStatistics _calculateDiaperStatistics(
    List<ActivityModel> activities,
    List<ActivityModel> lastWeekActivities,
    DateRange dateRange,
  ) {
    final diaperActivities = activities
        .where((a) => a.type == ActivityType.diaper)
        .toList();
    final lastWeekDiaper = lastWeekActivities
        .where((a) => a.type == ActivityType.diaper)
        .toList();

    // 요일별 기저귀 교체 횟수 (월~일)
    final dailyCounts = List.filled(7, 0);
    int wetCount = 0;
    int dirtyCount = 0;
    int bothCount = 0;

    for (final activity in diaperActivities) {
      final dayIndex = (activity.startTime.weekday - 1) % 7;
      dailyCounts[dayIndex]++;

      final diaperType = activity.diaperType;
      if (diaperType == 'wet') {
        wetCount++;
      } else if (diaperType == 'dirty') {
        dirtyCount++;
      } else if (diaperType == 'both') {
        bothCount++;
      }
    }

    final totalCount = diaperActivities.length;
    final dayCount = dateRange.dayCount > 0 ? dateRange.dayCount : 1;
    final dailyAverage = totalCount / dayCount;

    // 지난 주 대비 변화
    final lastWeekDailyAverage = lastWeekDiaper.length / 7;
    final changeCount = (dailyAverage - lastWeekDailyAverage).round();

    return DiaperStatistics(
      dailyAverageCount: dailyAverage,
      changeCount: changeCount,
      dailyCounts: dailyCounts,
      wetRatio: totalCount > 0 ? wetCount / totalCount : 0,
      dirtyRatio: totalCount > 0 ? dirtyCount / totalCount : 0,
      bothRatio: totalCount > 0 ? bothCount / totalCount : 0,
    );
  }
}

/// 아기 정보 (함께 보기용)
class BabyInfo {
  final String id;
  final String name;
  final int? correctedAgeDays;

  const BabyInfo({
    required this.id,
    required this.name,
    this.correctedAgeDays,
  });
}
