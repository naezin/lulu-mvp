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
import '../../statistics/models/weekly_statistics.dart';
import '../../statistics/widgets/together_guide_dialog.dart';
import '../../statistics/widgets/insight_card.dart';
import '../models/daily_pattern.dart' show PatternFilter;
import '../providers/pattern_data_provider.dart';
import 'date_navigator.dart';
import 'stat_summary_card.dart';
import 'weekly_chart_full.dart';

part 'week_calendar_picker_sheet.dart';

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

  /// Sprint 20 HF #8: 이전 babyId 추적 (변경 감지용)
  String? _previousBabyId;

  @override
  void initState() {
    super.initState();
    _dataProvider = StatisticsDataProvider();
    _filterProvider = StatisticsFilterProvider();
    _patternProvider = PatternDataProvider();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeProvider = context.read<HomeProvider>();
      _previousBabyId = homeProvider.selectedBabyId ?? homeProvider.babies.firstOrNull?.id;
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
  /// HF-6: 현재 주는 오늘까지만, 과거 주는 7일 풀
  Future<void> _onWeekChanged(DateTime newWeekStart) async {
    final homeProvider = context.read<HomeProvider>();
    final family = homeProvider.family;
    final selectedBaby = homeProvider.selectedBaby;

    if (family == null || selectedBaby == null) return;

    // HF-6: 현재 주이면 end=오늘, 과거 주이면 end=일요일
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekSunday = newWeekStart.add(const Duration(days: 6));
    final weekEnd = weekSunday.isAfter(today) ? today : weekSunday;
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

    // Sprint 20 HF #8: 아기 전환 감지 → 데이터 리로드
    // Sprint 21 Phase 2-4: context.select for granular rebuild
    final currentBabyId = context.select<HomeProvider, String?>((p) => p.selectedBabyId)
        ?? context.select<HomeProvider, String?>((p) => p.babies.firstOrNull?.id);
    if (currentBabyId != null && currentBabyId != _previousBabyId && !_isLoading) {
      _previousBabyId = currentBabyId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadData();
      });
    }

    // DateNavigator is always visible (loading/error/empty/normal)
    return RefreshIndicator(
      onRefresh: _loadData,
      color: LuluColors.lavenderMist,
      backgroundColor: LuluColors.surfaceCard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 주간 DateNavigator (항상 최상단)
            DateNavigator(
              scope: DateNavigatorScope.weekly,
              selectedDate: _patternProvider.weekStartDate,
              onDateChanged: _onWeekChanged,
              canGoNext: !_isCurrentWeek(),
              onCalendarTap: () => _showWeekPicker(context),
            ),

            // 상태별 콘텐츠
            if (_isLoading)
              _buildLoadingContent()
            else if (_errorMessage != null)
              _buildErrorContent()
            else if (_isStatisticsEmpty(_dataProvider.currentStatistics))
              _buildEmptyContent()
            else
              _buildStatisticsContent(l10n),
          ],
        ),
      ),
    );
  }

  /// 정상 통계 콘텐츠
  Widget _buildStatisticsContent(S? l10n) {
    final stats = _dataProvider.currentStatistics!;
    final selectedBaby = context.read<HomeProvider>().selectedBaby;
    final correctedAgeDays = selectedBaby?.correctedAgeInDays;

    return Padding(
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
              if (context.read<HomeProvider>().babies.length > 1) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TogetherViewButton(
                      isEnabled: _patternProvider.togetherViewEnabled,
                      onTap: () => _toggleTogetherView(context.read<HomeProvider>()),
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
                  final babyName = context.read<HomeProvider>().babies.length > index
                      ? context.read<HomeProvider>().babies[index].name
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
    );
  }

  /// 인사이트 카드
  /// Sprint 21 HF #13: InsightCard 위젯 사용 (i18n 키 → 로컬라이즈)
  Widget _buildInsightCard() {
    return InsightCard(insight: _dataProvider.insight!);
  }

  /// 로딩 콘텐츠 (DateNavigator 아래에 표시)
  Widget _buildLoadingContent() {
    final l10n = S.of(context);
    return SizedBox(
      height: 300,
      child: Center(
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
      ),
    );
  }

  /// 에러 콘텐츠 (DateNavigator 아래에 표시)
  Widget _buildErrorContent() {
    final l10n = S.of(context);
    return SizedBox(
      height: 300,
      child: Center(
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
      ),
    );
  }

  /// 빈 상태 콘텐츠 (DateNavigator 아래에 표시)
  Widget _buildEmptyContent() {
    final l10n = S.of(context);
    final isThisWeek = _isCurrentWeek();

    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: LuluColors.lavenderSelected,
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
              isThisWeek
                  ? (l10n?.weeklyEmptyThisWeek ?? 'Start your first record this week')
                  : (l10n?.weeklyEmptyPastWeek ?? 'No records for this week'),
              style: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

// _WeekCalendarPickerSheet → week_calendar_picker_sheet.dart (part file)
