import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../home/providers/home_provider.dart';
import '../../statistics/providers/statistics_data_provider.dart';
import '../../statistics/providers/statistics_filter_provider.dart';
import '../../statistics/models/insight_data.dart';
import '../../statistics/models/weekly_statistics.dart';
import '../../statistics/widgets/together_guide_dialog.dart';
import '../models/daily_pattern.dart' show PatternFilter;
import '../providers/pattern_data_provider.dart';
import 'date_navigator.dart';
import 'stat_summary_card.dart';
import 'weekly_chart_full.dart';

/// 주간 뷰 (WeeklyView)
///
/// Sprint 18-R Hotfix FIX-A: StatisticsTab에서 분리
/// - StatSummaryCard: 수면/수유/기저귀 요약
/// - WeeklyTrendChart: 주간 수면 추이
/// - WeeklyPatternChart: 7일x48슬롯 히트맵
/// - AI 인사이트 (있으면)
class WeeklyView extends StatefulWidget {
  const WeeklyView({super.key});

  @override
  State<WeeklyView> createState() => _WeeklyViewState();
}

class _WeeklyViewState extends State<WeeklyView> {
  late StatisticsDataProvider _dataProvider;
  late StatisticsFilterProvider _filterProvider;
  late PatternDataProvider _patternProvider;
  bool _isLoading = true;
  String? _errorMessage;

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

      debugPrint(
          '[DEBUG] [WeeklyView] family: ${family?.id}, babies: ${babies.length}, selectedBabyId: $selectedBabyId');

      if (family == null || babies.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = S.of(context)?.familyInfoMissing;
        });
        return;
      }

      final dateRange = _filterProvider.getDateRange();
      debugPrint(
          '[DEBUG] [WeeklyView] dateRange: ${dateRange.start} ~ ${dateRange.end}');

      // 타임아웃 처리 추가
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

      debugPrint(
          '[DEBUG] [WeeklyView] currentStatistics: ${_dataProvider.currentStatistics}');
      debugPrint('[DEBUG] [WeeklyView] hasData: ${_dataProvider.hasData}');

      // 주간 패턴 로드 (별도 타임아웃 - 실패해도 통계는 표시)
      final selectedBaby = homeProvider.selectedBaby;
      if (selectedBaby != null) {
        try {
          await _patternProvider
              .loadWeeklyPattern(
            familyId: family.id,
            babyId: selectedBaby.id,
            babyName: selectedBaby.name,
          )
              .timeout(
            Duration(seconds: _loadTimeoutSeconds),
            onTimeout: () {
              debugPrint(
                  '[WARN] [WeeklyView] Pattern load timeout - showing stats without pattern');
              return;
            },
          );
        } catch (patternError) {
          debugPrint('[WARN] [WeeklyView] Pattern load error: $patternError');
          // 패턴 로드 실패해도 통계는 계속 표시
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } on TimeoutException catch (e) {
      debugPrint('[ERROR] [WeeklyView] Timeout: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = S.of(context)?.dataLoadTimeout;
        });
      }
    } catch (e) {
      debugPrint('[ERROR] [WeeklyView] Load error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = S.of(context)?.dataLoadFailed;
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

  /// 현재 주인지 확인
  bool _isCurrentWeek() {
    final weekStart = _patternProvider.weekStartDate;
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    return weekStart.year == currentWeekStart.year &&
        weekStart.month == currentWeekStart.month &&
        weekStart.day == currentWeekStart.day;
  }

  /// DateNavigator에서 호출: 주간 변경
  Future<void> _onWeekChanged(DateTime newWeekStart) async {
    final homeProvider = context.read<HomeProvider>();
    final family = homeProvider.family;
    final selectedBaby = homeProvider.selectedBaby;

    if (family == null || selectedBaby == null) return;

    // 요약카드 + 차트 데이터 동시 갱신
    final weekEnd = newWeekStart.add(const Duration(days: 6));
    final weekDateRange = DateRange(start: newWeekStart, end: weekEnd);

    await Future.wait([
      _patternProvider.loadWeeklyPattern(
        familyId: family.id,
        babyId: selectedBaby.id,
        babyName: selectedBaby.name,
        weekStart: newWeekStart,
      ),
      _dataProvider.loadStatistics(
        familyId: family.id,
        babyId: selectedBaby.id,
        dateRange: weekDateRange,
      ),
    ]);
    if (mounted) setState(() {});
  }

  /// 주간 캘린더 피커 표시
  void _showWeekPicker(BuildContext context) {
    showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _WeekCalendarPickerSheet(
        selectedWeekStart: _patternProvider.weekStartDate,
      ),
    ).then((pickedWeekStart) {
      if (pickedWeekStart != null) {
        _onWeekChanged(pickedWeekStart);
      }
    });
  }

  /// 다태아 함께보기 토글
  void _toggleTogetherView(HomeProvider homeProvider) {
    final family = homeProvider.family;
    final babies = homeProvider.babies;

    if (family == null || babies.length <= 1) return;

    _patternProvider.toggleTogetherView();

    // 함께보기 활성화 시 모든 아기 패턴 로드
    if (_patternProvider.togetherViewEnabled) {
      // 첫 진입 시 가이드 다이얼로그 표시
      _showTogetherGuideIfNeeded();

      _patternProvider.loadMultiplePatterns(
        familyId: family.id,
        babyIds: babies.map((b) => b.id).toList(),
        babyNames: babies.map((b) => b.name).toList(),
      );
    }

    setState(() {});
  }

  /// 함께보기 가이드 다이얼로그 (최초 1회)
  Future<void> _showTogetherGuideIfNeeded() async {
    // TODO: SharedPreferences로 최초 1회만 표시
    await showDialog(
      context: context,
      builder: (context) => const TogetherGuideDialog(),
    );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 주간 DateNavigator (최상단)
            DateNavigator(
              scope: DateNavigatorScope.weekly,
              selectedDate: _patternProvider.weekStartDate,
              onDateChanged: _onWeekChanged,
              canGoNext: !_isCurrentWeek(),
              onCalendarTap: () => _showWeekPicker(context),
            ),

            Padding(
              padding: const EdgeInsets.all(LuluSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // 요약 카드들 (2×2 GridView)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: LuluSpacing.sm,
              crossAxisSpacing: LuluSpacing.sm,
              childAspectRatio: 1.5,
              children: [
                StatSummaryCard(
                  type: StatType.sleep,
                  value: stats.sleep.dailyAverageHours,
                  unit: l10n?.unitHours ?? 'h',
                  change: stats.sleep.changeMinutes.toDouble(),
                  correctedAgeDays: correctedAgeDays,
                ),
                StatSummaryCard(
                  type: StatType.feeding,
                  value: stats.feeding.dailyAverageCount,
                  unit: l10n?.unitTimes ?? 'times',
                  change: stats.feeding.changeCount.toDouble(),
                  correctedAgeDays: correctedAgeDays,
                ),
                StatSummaryCard(
                  type: StatType.diaper,
                  value: stats.diaper.dailyAverageCount,
                  unit: l10n?.unitTimes ?? 'times',
                  change: stats.diaper.changeCount.toDouble(),
                  correctedAgeDays: correctedAgeDays,
                ),
                StatSummaryCard(
                  type: StatType.play,
                  value: stats.play?.dailyAverageMinutes ?? 0,
                  unit: 'min',
                  change: stats.play?.changeMinutes.toDouble() ?? 0,
                  correctedAgeDays: correctedAgeDays,
                ),
              ],
            ),

            const SizedBox(height: LuluSpacing.xl),

            // 주간 패턴 차트 (Sprint 19 v5: 세로 스택 렌더링)
            if (_patternProvider.isLoading) ...[
              _buildChartSkeleton(),
              const SizedBox(height: LuluSpacing.xl),
            ] else if (_patternProvider.weekTimelines.isNotEmpty) ...[
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

              // 함께보기 모드
              if (_patternProvider.togetherViewEnabled &&
                  _patternProvider.multipleWeekTimelines.isNotEmpty) ...[
                ..._patternProvider.multipleWeekTimelines.asMap().entries.map((entry) {
                  final index = entry.key;
                  final timelines = entry.value;
                  final babyName = homeProvider.babies.length > index
                      ? homeProvider.babies[index].name
                      : '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: LuluSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          babyName,
                          style: LuluTextStyles.labelMedium.copyWith(
                            color: LuluColors.lavenderMist,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: LuluSpacing.xs),
                        WeeklyChartFull(
                          weekTimelines: timelines,
                          weekStartDate: _patternProvider.weekStartDate,
                          filter: _filterToString(_patternProvider.filter),
                          onFilterChanged: (filter) {
                            setState(() {
                              _patternProvider.setFilter(_stringToFilter(filter));
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ] else ...[
                // 단일 아기 모드
                WeeklyChartFull(
                  weekTimelines: _patternProvider.weekTimelines,
                  weekStartDate: _patternProvider.weekStartDate,
                  filter: _filterToString(_patternProvider.filter),
                  onFilterChanged: (filter) {
                    setState(() {
                      _patternProvider.setFilter(_stringToFilter(filter));
                    });
                  },
                ),
              ],
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
            ), // Padding end
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
        borderRadius: BorderRadius.circular(LuluRadius.sm),
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
            _errorMessage ?? l10n?.errorOccurred ?? 'Something went wrong',
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

  /// 차트 스켈레톤
  Widget _buildChartSkeleton() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: LuluColors.chartSkeletonBg,
        borderRadius: BorderRadius.circular(LuluRadius.md),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: LuluColors.lavenderMist,
          strokeWidth: 2,
        ),
      ),
    );
  }

  /// PatternFilter → String 변환
  String? _filterToString(PatternFilter filter) {
    switch (filter) {
      case PatternFilter.sleep:
        return 'sleep';
      case PatternFilter.feeding:
        return 'feeding';
      case PatternFilter.diaper:
        return 'diaper';
      case PatternFilter.play:
        return 'play';
      case PatternFilter.health:
        return 'health';
      case PatternFilter.all:
        return null;
    }
  }

  /// String → PatternFilter 변환
  PatternFilter _stringToFilter(String? filter) {
    switch (filter) {
      case 'sleep':
        return PatternFilter.sleep;
      case 'feeding':
        return PatternFilter.feeding;
      case 'diaper':
        return PatternFilter.diaper;
      case 'play':
        return PatternFilter.play;
      case 'health':
        return PatternFilter.health;
      default:
        return PatternFilter.all;
    }
  }
}

/// 주간 캘린더 피커 (BottomSheet)
///
/// 월간 달력에서 주 단위 행을 탭하면 해당 주 시작일(월요일) 반환.
/// LuluColors.weekPickerSelected로 선택 주 행 하이라이트.
class _WeekCalendarPickerSheet extends StatefulWidget {
  final DateTime selectedWeekStart;

  const _WeekCalendarPickerSheet({
    required this.selectedWeekStart,
  });

  @override
  State<_WeekCalendarPickerSheet> createState() =>
      _WeekCalendarPickerSheetState();
}

class _WeekCalendarPickerSheetState extends State<_WeekCalendarPickerSheet> {
  late DateTime _displayMonth;
  late DateTime _hoveredWeekStart;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(
      widget.selectedWeekStart.year,
      widget.selectedWeekStart.month,
    );
    _hoveredWeekStart = widget.selectedWeekStart;
  }

  /// Get Monday of the week containing [date]
  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Navigate months
  void _goToPreviousMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    if (nextMonth.isAfter(DateTime(now.year, now.month + 1))) return;
    setState(() {
      _displayMonth = nextMonth;
    });
  }

  /// Jump to this week
  void _goToThisWeek() {
    final now = DateTime.now();
    final thisWeekStart = _getWeekStart(now);
    Navigator.of(context).pop(thisWeekStart);
  }

  /// Build the calendar grid weeks
  List<List<DateTime>> _buildCalendarWeeks() {
    final firstDayOfMonth = DateTime(_displayMonth.year, _displayMonth.month);
    final lastDayOfMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0);

    // Start from the Monday on or before the 1st
    final calendarStart = _getWeekStart(firstDayOfMonth);

    final weeks = <List<DateTime>>[];
    var current = calendarStart;

    while (current.isBefore(lastDayOfMonth) ||
        current.month == _displayMonth.month ||
        weeks.length < 5) {
      final week = List.generate(7, (i) => current.add(Duration(days: i)));
      weeks.add(week);
      current = current.add(const Duration(days: 7));
      if (weeks.length >= 6) break;
    }

    return weeks;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(date, now);
  }

  bool _isFutureWeek(DateTime weekStart) {
    final now = DateTime.now();
    final thisWeekStart = _getWeekStart(now);
    return weekStart.isAfter(thisWeekStart);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final weeks = _buildCalendarWeeks();

    return Container(
      decoration: const BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.lg,
        vertical: LuluSpacing.md,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: LuluSpacing.md),
              decoration: BoxDecoration(
                color: LuluColors.glassBorder,
                borderRadius: BorderRadius.circular(LuluRadius.xxs),
              ),
            ),

            // Title + This Week button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.weekPickerTitle ?? 'Select Week',
                  style: LuluTextStyles.titleSmall.copyWith(
                    color: LuluTextColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: _goToThisWeek,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LuluSpacing.sm,
                      vertical: LuluSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: LuluColors.navButtonBg,
                      borderRadius: BorderRadius.circular(LuluRadius.xs),
                    ),
                    child: Text(
                      l10n?.weekPickerThisWeek ?? 'This Week',
                      style: LuluTextStyles.caption.copyWith(
                        color: LuluColors.lavenderMist,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: LuluSpacing.md),

            // Month navigator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _goToPreviousMonth,
                  child: Padding(
                    padding: const EdgeInsets.all(LuluSpacing.xs),
                    child: Icon(
                      LuluIcons.chevronLeft,
                      size: 20,
                      color: LuluTextColors.primary,
                    ),
                  ),
                ),
                Text(
                  _formatMonthYear(_displayMonth),
                  style: LuluTextStyles.bodyMedium.copyWith(
                    color: LuluTextColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: _goToNextMonth,
                  child: Padding(
                    padding: const EdgeInsets.all(LuluSpacing.xs),
                    child: Icon(
                      LuluIcons.chevronRight,
                      size: 20,
                      color: LuluTextColors.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: LuluSpacing.sm),

            // Weekday headers (Mon ~ Sun)
            _buildWeekdayHeaders(l10n),

            const SizedBox(height: LuluSpacing.xs),

            // Calendar weeks (tappable rows)
            ...weeks.map((week) => _buildWeekRow(week)),

            const SizedBox(height: LuluSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayHeaders(S? l10n) {
    final headers = [
      l10n?.weekdayMon ?? 'Mon',
      l10n?.weekdayTue ?? 'Tue',
      l10n?.weekdayWed ?? 'Wed',
      l10n?.weekdayThu ?? 'Thu',
      l10n?.weekdayFri ?? 'Fri',
      l10n?.weekdaySat ?? 'Sat',
      l10n?.weekdaySun ?? 'Sun',
    ];

    return Row(
      children: headers
          .map(
            (h) => Expanded(
              child: Center(
                child: Text(
                  h,
                  style: LuluTextStyles.caption.copyWith(
                    color: LuluTextColors.tertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildWeekRow(List<DateTime> week) {
    final weekStart = _getWeekStart(week.first);
    final isSelected = _isSameDay(weekStart, _hoveredWeekStart);
    final isFuture = _isFutureWeek(weekStart);

    return GestureDetector(
      onTap: isFuture
          ? null
          : () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop(weekStart);
            },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: isSelected ? LuluColors.weekPickerSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(LuluRadius.xs),
        ),
        padding: const EdgeInsets.symmetric(vertical: LuluSpacing.sm),
        child: Row(
          children: week.map((date) {
            final isCurrentMonth = date.month == _displayMonth.month;
            final today = _isToday(date);

            return Expanded(
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: today
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          color: LuluColors.lavenderMist,
                        )
                      : null,
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: LuluTextStyles.bodySmall.copyWith(
                      color: isFuture
                          ? LuluTextColors.tertiary
                          : today
                              ? LuluColors.midnightNavy
                              : isCurrentMonth
                                  ? LuluTextColors.primary
                                  : LuluTextColors.tertiary,
                      fontWeight: today ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatMonthYear(DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ko') {
      return '${date.year}.${date.month}';
    }
    return DateFormat.yMMMM(locale).format(date);
  }
}
