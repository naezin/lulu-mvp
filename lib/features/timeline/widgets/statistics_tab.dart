import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../home/providers/home_provider.dart';
import '../../statistics/providers/statistics_data_provider.dart';
import '../../statistics/providers/statistics_filter_provider.dart';
import '../../statistics/models/insight_data.dart';
import '../../statistics/models/weekly_statistics.dart';
import '../providers/pattern_data_provider.dart';
import 'stat_summary_card.dart';
import 'weekly_trend_chart.dart';
import 'weekly_chart_full.dart';
import '../models/day_timeline.dart';

/// 통계 탭
///
/// RecordHistoryScreen의 두 번째 탭
/// - 주간 통계 요약
/// - 트렌드 차트
/// - 권장 범위 뱃지
class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  late StatisticsDataProvider _dataProvider;
  late StatisticsFilterProvider _filterProvider;
  late PatternDataProvider _patternProvider;
  bool _isLoading = true;
  String? _errorMessage;

  // 🔧 Sprint 19 FIX (버그 2): HomeProvider 변경 감지
  int _lastActivityCount = -1;

  // Sprint 19 v2: WeeklyChartFull용 상태
  List<DayTimeline> _weekTimelines = [];
  String? _chartFilter;
  DateTime _weekStartDate = _getWeekStart(DateTime.now());

  static DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysFromMonday));
  }

  @override
  void initState() {
    super.initState();
    _dataProvider = StatisticsDataProvider();
    _filterProvider = StatisticsFilterProvider();
    _patternProvider = PatternDataProvider();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 🔧 Sprint 19 FIX (버그 2): HomeProvider의 활동 개수 변경 시 데이터 새로 로드
    final homeProvider = context.watch<HomeProvider>();
    final currentCount = homeProvider.todayActivities.length;

    if (_lastActivityCount != -1 && _lastActivityCount != currentCount) {
      debugPrint('[DEBUG] [StatisticsTab] Activity count changed: $_lastActivityCount -> $currentCount, reloading...');
      _patternProvider.clearCache(); // 캐시 무효화
      _loadData();
    }
    _lastActivityCount = currentCount;
  }

  @override
  void dispose() {
    _dataProvider.dispose();
    _filterProvider.dispose();
    _patternProvider.dispose();
    super.dispose();
  }

  /// 데이터 로드 타임아웃 (초)
  static const int _loadTimeoutSeconds = 15;

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final homeProvider = context.read<HomeProvider>();
      final family = homeProvider.family;
      final babies = homeProvider.babies;
      final selectedBabyId = homeProvider.selectedBabyId;

      debugPrint('[DEBUG] [StatisticsTab] family: ${family?.id}, babies: ${babies.length}, selectedBabyId: $selectedBabyId');

      if (family == null || babies.isEmpty) {
        final l10n = S.of(context);
        setState(() {
          _isLoading = false;
          _errorMessage = l10n?.familyInfoMissing ?? 'Family info not found';
        });
        return;
      }

      final dateRange = _filterProvider.getDateRange();
      debugPrint('[DEBUG] [StatisticsTab] dateRange: ${dateRange.start} ~ ${dateRange.end}');

      // ⚠️ BUG-002 FIX: 타임아웃 처리 추가
      await Future.wait([
        _dataProvider.loadStatistics(
          familyId: family.id,
          babyId: selectedBabyId,
          dateRange: dateRange,
        ),
      ]).timeout(
        Duration(seconds: _loadTimeoutSeconds),
        onTimeout: () {
          throw TimeoutException('Statistics loading timeout');
        },
      );

      debugPrint('[DEBUG] [StatisticsTab] currentStatistics: ${_dataProvider.currentStatistics}');
      debugPrint('[DEBUG] [StatisticsTab] hasData: ${_dataProvider.hasData}');

      // Sprint 19 v2: WeeklyChartFull용 DayTimeline 로드
      final selectedBaby = homeProvider.selectedBaby;
      if (selectedBaby != null) {
        try {
          // 레거시 패턴 로드 (기존 호환)
          await _patternProvider.loadWeeklyPattern(
            familyId: family.id,
            babyId: selectedBaby.id,
            babyName: selectedBaby.name,
          ).timeout(
            Duration(seconds: _loadTimeoutSeconds),
            onTimeout: () {
              debugPrint('⚠️ [StatisticsTab] Pattern load timeout - showing stats without pattern');
              return;
            },
          );

          // Sprint 19 v2: DayTimeline 기반 데이터 로드
          final timelines = await _patternProvider.getWeekTimelines(
            familyId: family.id,
            babyId: selectedBaby.id,
            weekStart: _weekStartDate,
          );
          if (mounted) {
            setState(() {
              _weekTimelines = timelines;
            });
          }
        } catch (patternError) {
          debugPrint('⚠️ [StatisticsTab] Pattern load error: $patternError');
          // 패턴 로드 실패해도 통계는 계속 표시
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } on TimeoutException catch (e) {
      debugPrint('⏱️ [StatisticsTab] Timeout: $e');
      if (mounted) {
        final l10n = S.of(context);
        setState(() {
          _isLoading = false;
          _errorMessage = l10n?.dataLoadTimeout ?? 'Data loading timeout';
        });
      }
    } catch (e) {
      debugPrint('❌ [StatisticsTab] Load error: $e');
      if (mounted) {
        final l10n = S.of(context);
        setState(() {
          _isLoading = false;
          _errorMessage = l10n?.dataLoadFailed ?? 'Failed to load data';
        });
      }
    }
  }

  /// 통계가 실질적으로 비어있는지 확인
  bool _isStatisticsEmpty(WeeklyStatistics? stats) {
    if (stats == null) return true;
    // 모든 활동이 0이면 빈 상태
    return stats.sleep.dailyAverageHours == 0 &&
        stats.feeding.dailyAverageCount == 0 &&
        stats.diaper.dailyAverageCount == 0;
  }

  /// 주간 네비게이션 (Sprint 19 v2: DayTimeline 로드 추가)
  Future<void> _navigateWeek({required bool isPrevious}) async {
    final homeProvider = context.read<HomeProvider>();
    final family = homeProvider.family;
    final selectedBaby = homeProvider.selectedBaby;

    if (family == null || selectedBaby == null) return;

    // 주간 시작일 업데이트
    setState(() {
      if (isPrevious) {
        _weekStartDate = _weekStartDate.subtract(const Duration(days: 7));
      } else {
        final newStart = _weekStartDate.add(const Duration(days: 7));
        if (!newStart.isAfter(DateTime.now())) {
          _weekStartDate = newStart;
        }
      }
    });

    // 레거시 패턴 로드
    if (isPrevious) {
      _patternProvider.goToPreviousWeek(
        familyId: family.id,
        babyId: selectedBaby.id,
        babyName: selectedBaby.name,
      );
    } else {
      _patternProvider.goToNextWeek(
        familyId: family.id,
        babyId: selectedBaby.id,
        babyName: selectedBaby.name,
      );
    }

    // Sprint 19 v2: DayTimeline 로드
    try {
      final timelines = await _patternProvider.getWeekTimelines(
        familyId: family.id,
        babyId: selectedBaby.id,
        weekStart: _weekStartDate,
      );
      if (mounted) {
        setState(() {
          _weekTimelines = timelines;
        });
      }
    } catch (e) {
      debugPrint('[WARN] [StatisticsTab] Timeline load error: $e');
    }
  }

  /// 현재 주인지 확인
  bool _isCurrentWeek() {
    final weekStart = _patternProvider.weekStartDate;
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    return weekStart.year == currentWeekStart.year &&
        weekStart.month == currentWeekStart.month &&
        weekStart.day == currentWeekStart.day;
  }

  /// 다태아 함께보기 토글
  void _toggleTogetherView(HomeProvider homeProvider) {
    final family = homeProvider.family;
    final babies = homeProvider.babies;

    if (family == null || babies.length <= 1) return;

    _patternProvider.toggleTogetherView();

    // 함께보기 활성화 시 모든 아기 패턴 로드
    if (_patternProvider.togetherViewEnabled) {
      _patternProvider.loadMultiplePatterns(
        familyId: family.id,
        babyIds: babies.map((b) => b.id).toList(),
        babyNames: babies.map((b) => b.name).toList(),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final statistics = _dataProvider.currentStatistics;

    // 데이터가 없거나 모든 값이 0이면 빈 상태
    if (_isStatisticsEmpty(statistics)) {
      return _buildEmptyState();
    }

    // null이 아님이 보장됨
    final stats = statistics!;

    final homeProvider = context.watch<HomeProvider>();
    final selectedBaby = homeProvider.selectedBaby;
    final correctedAgeDays = selectedBaby?.correctedAgeInDays;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: LuluColors.lavenderMist,
      backgroundColor: LuluColors.surfaceCard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(LuluSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 요약 카드들
            Row(
              children: [
                Expanded(
                  child: StatSummaryCard(
                    type: StatType.sleep,
                    value: stats.sleep.dailyAverageHours,
                    unit: l10n?.unitHours ?? 'h',
                    change: stats.sleep.changeMinutes.toDouble(),
                    correctedAgeDays: correctedAgeDays,
                  ),
                ),
                const SizedBox(width: LuluSpacing.sm),
                Expanded(
                  child: StatSummaryCard(
                    type: StatType.feeding,
                    value: stats.feeding.dailyAverageCount,
                    unit: l10n?.unitTimes ?? 'times',
                    change: stats.feeding.changeCount.toDouble(),
                    correctedAgeDays: correctedAgeDays,
                    // 🔧 Sprint 19 E: ml 표시
                    feedingMl: stats.feeding.dailyAverageMl,
                    feedingCount: stats.feeding.dailyAverageCount,
                  ),
                ),
                const SizedBox(width: LuluSpacing.sm),
                Expanded(
                  child: StatSummaryCard(
                    type: StatType.diaper,
                    value: stats.diaper.dailyAverageCount,
                    unit: l10n?.unitTimes ?? 'times',
                    change: stats.diaper.changeCount.toDouble(),
                    correctedAgeDays: correctedAgeDays,
                  ),
                ),
              ],
            ),

            const SizedBox(height: LuluSpacing.xl),

            // 주간 수면 트렌드 차트
            Text(
              l10n?.weeklyTrendTitle ?? 'Weekly Sleep Trend',
              style: LuluTextStyles.titleSmall.copyWith(
                color: LuluTextColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: LuluSpacing.md),
            WeeklyTrendChart(
              dailyHours: stats.sleep.dailyHours,
              barColor: LuluActivityColors.sleep,
              highlightIndex: _dataProvider.insight?.highlightDayIndex,
            ),

            const SizedBox(height: LuluSpacing.xl),

            // Sprint 19 v2: WeeklyChartFull (DayTimeline 기반)
            if (_patternProvider.isLoading) ...[
              _buildChartSkeleton(),
              const SizedBox(height: LuluSpacing.xl),
            ] else ...[
              // 다태아인 경우 함께보기 버튼 표시
              if (homeProvider.babies.length > 1) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TogetherViewButton(
                      isEnabled: _patternProvider.togetherViewEnabled,
                      onTap: () => _toggleTogetherView(homeProvider),
                    ),
                  ],
                ),
                const SizedBox(height: LuluSpacing.sm),
              ],

              // Sprint 19 v2: WeeklyChartFull
              WeeklyChartFull(
                weekTimelines: _weekTimelines,
                weekStartDate: _weekStartDate,
                filter: _chartFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _chartFilter = filter;
                  });
                },
                onPreviousWeek: () => _navigateWeek(isPrevious: true),
                onNextWeek: () => _navigateWeek(isPrevious: false),
                canGoNext: !_isCurrentWeek(),
              ),
              const SizedBox(height: LuluSpacing.xl),
            ],

            // AI 인사이트 (있으면)
            if (_dataProvider.insight != null) ...[
              _buildInsightCard(),
              const SizedBox(height: LuluSpacing.lg),
            ],

            // 의료 면책 문구
            Center(
              child: Text(
                l10n?.statisticsDisclaimer ?? 'Statistics are for reference only, not medical advice',
                style: LuluTextStyles.caption.copyWith(
                  color: LuluTextColors.tertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: LuluSpacing.lg),
          ],
        ),
      ),
    );
  }

  /// 인사이트 카드
  Widget _buildInsightCard() {
    final insight = _dataProvider.insight!;
    final color = switch (insight.type) {
      InsightType.positive => LuluStatusColors.success,
      InsightType.attention => LuluStatusColors.warning,
      InsightType.neutral => LuluColors.lavenderMist,
    };

    return Container(
      padding: const EdgeInsets.all(LuluSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            LuluIcons.tip,
            color: color,
            size: 24,
          ),
          const SizedBox(width: LuluSpacing.sm),
          Expanded(
            child: Text(
              insight.message,
              style: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 로딩 상태
  Widget _buildLoadingState() {
    final l10n = S.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: LuluColors.lavenderMist,
          ),
          const SizedBox(height: LuluSpacing.md),
          Text(
            l10n?.statisticsLoading ?? 'Loading statistics...',
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Sprint 19 v2: 차트 스켈레톤
  Widget _buildChartSkeleton() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: LuluColors.chartSkeletonBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LuluColors.chartSkeletonBorder,
          width: 1,
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: LuluColors.lavenderMist,
          strokeWidth: 2,
        ),
      ),
    );
  }

  /// 에러 상태
  Widget _buildErrorState() {
    final l10n = S.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LuluIcons.errorOutline,
            size: 64,
            color: LuluStatusColors.error,
          ),
          const SizedBox(height: LuluSpacing.md),
          Text(
            _errorMessage ?? l10n?.errorOccurred ?? 'An error occurred',
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.primary,
            ),
          ),
          const SizedBox(height: LuluSpacing.md),
          TextButton(
            onPressed: _loadData,
            child: Text(
              l10n?.retry ?? 'Retry',
              style: LuluTextStyles.bodyMedium.copyWith(
                color: LuluColors.lavenderMist,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 빈 상태
  Widget _buildEmptyState() {
    final l10n = S.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: LuluColors.lavenderMist.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LuluIcons.barChart,
              size: 40,
              color: LuluColors.lavenderMist,
            ),
          ),
          const SizedBox(height: LuluSpacing.xl),
          Text(
            l10n?.statisticsEmptyTitle ?? 'No statistics yet',
            style: LuluTextStyles.titleMedium.copyWith(
              color: LuluTextColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: LuluSpacing.sm),
          Text(
            l10n?.statisticsEmptyHint ?? 'Statistics will appear as you add records',
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
