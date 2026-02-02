import 'package:flutter/foundation.dart';

import '../models/weekly_statistics.dart';
import '../models/together_data.dart';
import '../models/insight_data.dart';
import 'statistics_filter_provider.dart';

/// 통계 데이터 Provider
///
/// 작업 지시서 v1.2.1: 데이터 fetching + 캐싱
/// Provider 분리: 데이터 변경 시 → 차트만 리빌드
class StatisticsDataProvider extends ChangeNotifier {
  /// 캐시된 통계 데이터
  final Map<String, WeeklyStatistics> _cache = {};

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
    required String? babyId,
    required DateRange dateRange,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _buildCacheKey(babyId, dateRange);

    // 캐시 확인
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      _currentStatistics = _cache[cacheKey];
      _generateInsight();
      notifyListeners();
      return;
    }

    try {
      // TODO: 실제 Supabase에서 데이터 로드
      // 현재는 더미 데이터 사용
      final statistics = await _fetchStatistics(babyId, dateRange);

      _cache[cacheKey] = statistics;
      _currentStatistics = statistics;
      _lastSyncTime = DateTime.now();
      _isOffline = false;

      _generateInsight();
      notifyListeners();
    } catch (e) {
      // 오프라인이거나 에러 발생 시 캐시 데이터 사용
      if (_cache.containsKey(cacheKey)) {
        _currentStatistics = _cache[cacheKey];
        _isOffline = true;
        notifyListeners();
      } else {
        rethrow;
      }
    }
  }

  /// 함께 보기 데이터 로드
  Future<void> loadTogetherData({
    required List<String> babyIds,
    required DateRange dateRange,
  }) async {
    try {
      // TODO: 실제 Supabase에서 데이터 로드
      // 현재는 더미 데이터 사용
      _togetherData = await _fetchTogetherData(babyIds, dateRange);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load together data: $e');
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
    _cache.removeWhere((key, value) {
      return date.isAfter(value.startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(value.endDate.add(const Duration(days: 1)));
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

    final dayNames = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];

    // 인사이트 메시지 생성
    String message;
    InsightType type;

    if (sleep.changeMinutes > 30) {
      message = '수면 시간이 지난주보다 증가했어요';
      type = InsightType.positive;
    } else if (sleep.changeMinutes < -30) {
      message = '수면 시간이 지난주보다 감소했어요';
      type = InsightType.attention;
    } else if (maxHours > 0) {
      message = '${dayNames[maxDayIndex]}에 수면이 가장 많았어요';
      type = InsightType.neutral;
    } else {
      message = '이번 주 기록을 시작해보세요';
      type = InsightType.neutral;
    }

    _insight = InsightData(
      message: message,
      type: type,
      relatedReportType: 'sleep',
      highlightDayIndex: maxHours > 0 ? maxDayIndex : null,
    );
  }

  /// 더미 통계 데이터 생성 (개발용)
  Future<WeeklyStatistics> _fetchStatistics(
    String? babyId,
    DateRange dateRange,
  ) async {
    // 실제 구현에서는 Supabase 쿼리로 대체
    await Future.delayed(const Duration(milliseconds: 300));

    return WeeklyStatistics(
      sleep: const SleepStatistics(
        dailyAverageHours: 14.2,
        changeMinutes: 30,
        dailyHours: [12.5, 13.0, 14.0, 14.8, 13.5, 12.8, 14.2],
        napRatio: 0.3,
        nightRatio: 0.7,
        nightWakeups: 2,
      ),
      feeding: const FeedingStatistics(
        dailyAverageCount: 8.3,
        changeCount: 0,
        dailyCounts: [8, 9, 8, 7, 9, 8, 9],
        breastMilkRatio: 0.6,
        formulaRatio: 0.3,
        solidFoodRatio: 0.1,
      ),
      diaper: const DiaperStatistics(
        dailyAverageCount: 6.1,
        changeCount: -1,
        dailyCounts: [6, 7, 6, 5, 6, 7, 6],
        wetRatio: 0.5,
        dirtyRatio: 0.3,
        bothRatio: 0.2,
      ),
      startDate: dateRange.start,
      endDate: dateRange.end,
    );
  }

  /// 더미 함께 보기 데이터 생성 (개발용)
  Future<TogetherData> _fetchTogetherData(
    List<String> babyIds,
    DateRange dateRange,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 실제 구현에서는 각 아기별 데이터 로드
    return TogetherData(
      babies: [
        BabyStatisticsSummary(
          babyId: 'baby1',
          babyName: '민지',
          correctedAgeDays: 42,
          statistics: WeeklyStatistics(
            sleep: const SleepStatistics(
              dailyAverageHours: 14.5,
              changeMinutes: 30,
              dailyHours: [13.0, 14.0, 15.0, 14.5, 14.0, 13.5, 14.5],
              napRatio: 0.35,
              nightRatio: 0.65,
              nightWakeups: 2,
            ),
            feeding: const FeedingStatistics(
              dailyAverageCount: 8.5,
              changeCount: 0,
              dailyCounts: [8, 9, 8, 8, 9, 9, 8],
              breastMilkRatio: 0.7,
              formulaRatio: 0.2,
              solidFoodRatio: 0.1,
            ),
            diaper: const DiaperStatistics(
              dailyAverageCount: 6.3,
              changeCount: 0,
              dailyCounts: [6, 7, 6, 6, 7, 6, 6],
              wetRatio: 0.5,
              dirtyRatio: 0.3,
              bothRatio: 0.2,
            ),
            startDate: dateRange.start,
            endDate: dateRange.end,
          ),
        ),
        BabyStatisticsSummary(
          babyId: 'baby2',
          babyName: '민정',
          correctedAgeDays: 38,
          statistics: WeeklyStatistics(
            sleep: const SleepStatistics(
              dailyAverageHours: 13.8,
              changeMinutes: -15,
              dailyHours: [12.5, 13.5, 14.0, 14.0, 13.5, 13.0, 14.0],
              napRatio: 0.25,
              nightRatio: 0.75,
              nightWakeups: 1,
            ),
            feeding: const FeedingStatistics(
              dailyAverageCount: 8.1,
              changeCount: 1,
              dailyCounts: [8, 8, 8, 7, 9, 8, 9],
              breastMilkRatio: 0.5,
              formulaRatio: 0.4,
              solidFoodRatio: 0.1,
            ),
            diaper: const DiaperStatistics(
              dailyAverageCount: 5.9,
              changeCount: -1,
              dailyCounts: [6, 6, 5, 6, 6, 6, 6],
              wetRatio: 0.6,
              dirtyRatio: 0.25,
              bothRatio: 0.15,
            ),
            startDate: dateRange.start,
            endDate: dateRange.end,
          ),
        ),
      ],
      startDate: dateRange.start,
      endDate: dateRange.end,
    );
  }
}
