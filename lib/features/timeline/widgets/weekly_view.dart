import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../home/providers/home_provider.dart';
import '../../statistics/providers/statistics_data_provider.dart';
import '../../statistics/providers/statistics_filter_provider.dart';
import '../../statistics/models/insight_data.dart';
import '../../statistics/models/weekly_statistics.dart';
import '../../statistics/widgets/together_guide_dialog.dart';
import '../providers/pattern_data_provider.dart';
import '../models/daily_pattern.dart' show PatternActivityType;
import '../models/day_timeline.dart';
import 'date_navigator.dart';
import 'stat_summary_card.dart';
import 'weekly_chart_full.dart';
import 'weekly_grid.dart';
import 'weekly_insight.dart';
// HF2-9: WeeklyTrendChart 제거 (중복 정보)
import 'weekly_pattern_chart.dart';

/// 주간 뷰 (WeeklyView)
///
/// Sprint 19: 차트 재설계
/// - DateNavigator: 주간 날짜 탐색
/// - WeeklyChartFull: 실제 시간 기반 7일x24시간 차트 (신규)
/// - WeeklyGrid: 1x4 요약 그리드 (수면/수유/기저귀/놀이)
/// - WeeklyInsight: 트렌드 한줄 요약
/// - WeeklyPatternChart: 7일x48슬롯 히트맵 (유지)
/// - StatSummaryCard: 기존 요약 카드 (유지)
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

  /// HF3: 선택된 주의 시작일 (월요일)
  late DateTime _selectedWeekStart;

  @override
  void initState() {
    super.initState();
    _dataProvider = StatisticsDataProvider();
    _filterProvider = StatisticsFilterProvider();
    _patternProvider = PatternDataProvider();

    // 이번 주 월요일로 초기화
    final now = DateTime.now();
    _selectedWeekStart = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );

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

  /// 현재 선택된 주의 날짜 범위
  DateRange get _currentDateRange {
    final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
    return DateRange(start: _selectedWeekStart, end: weekEnd);
  }

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
          _errorMessage = '가족 정보가 없어요';
        });
        return;
      }

      final dateRange = _currentDateRange;
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
          throw TimeoutException('통계 로딩 타임아웃');
        },
      );

      // 주간 패턴 로드 (별도 타임아웃 - 실패해도 통계는 표시)
      final selectedBaby = homeProvider.selectedBaby;
      if (selectedBaby != null) {
        try {
          // HF7-FIX: 주간 데이터 로드 전 캐시 무효화 (최신 데이터 보장)
          final cacheKey = '${selectedBaby.id}-${_selectedWeekStart.toIso8601String()}';
          _patternProvider.invalidateCacheKey(cacheKey);

          await _patternProvider
              .loadWeeklyPattern(
            familyId: family.id,
            babyId: selectedBaby.id,
            babyName: selectedBaby.name,
            weekStart: _selectedWeekStart,
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
          _errorMessage = '데이터 로딩이 너무 오래 걸려요. 다시 시도해주세요.';
        });
      }
    } catch (e) {
      debugPrint('[ERROR] [WeeklyView] Load error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '데이터를 불러올 수 없어요';
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

  /// HF3: DateNavigator에서 호출 - 주 변경
  void _onWeekChanged(DateTime newWeekStart) {
    setState(() {
      _selectedWeekStart = DateTime(
        newWeekStart.year,
        newWeekStart.month,
        newWeekStart.day,
      );
    });
    _loadData();
  }

  /// 현재 주인지 확인
  bool get _isCurrentWeek {
    final now = DateTime.now();
    final currentWeekStart = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );
    return _selectedWeekStart.year == currentWeekStart.year &&
        _selectedWeekStart.month == currentWeekStart.month &&
        _selectedWeekStart.day == currentWeekStart.day;
  }

  /// HF6: 주간 선택 바텀시트 표시
  Future<void> _showWeekPicker(BuildContext context) async {
    final now = DateTime.now();
    final currentWeekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));

    // 아기 생년월일 가져오기 (최소 날짜)
    final homeProvider = context.read<HomeProvider>();
    final selectedBaby = homeProvider.selectedBaby;
    final babyBirthDate = selectedBaby?.birthDate ?? DateTime(2024, 1, 1);

    // 주 목록 생성 (최근 12주)
    final weeks = <DateTime>[];
    var weekStart = currentWeekStart;
    for (int i = 0; i < 12; i++) {
      if (weekStart.isAfter(babyBirthDate.subtract(const Duration(days: 7)))) {
        weeks.add(weekStart);
      }
      weekStart = weekStart.subtract(const Duration(days: 7));
    }

    final selectedWeek = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: LuluColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _WeekPickerSheet(
        weeks: weeks,
        selectedWeek: _selectedWeekStart,
        currentWeek: currentWeekStart,
      ),
    );

    if (selectedWeek != null) {
      _onWeekChanged(selectedWeek);
    }
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

  /// Sprint 19: WeeklyStatistics에서 WeeklySummary 생성
  WeeklySummary _buildWeeklySummary(WeeklyStatistics stats) {
    // 기존 통계에서 트렌드 계산
    final sleepTrend = stats.sleep.changeMinutes / 60.0; // 분 → 시간
    final feedGapTrend = 0.0; // TODO: 수유 간격 트렌드 (현재 데이터 없음)

    return WeeklySummary(
      avgSleepHours: stats.sleep.dailyAverageHours,
      avgFeedGap: 0.0, // TODO: 수유 간격 평균 (현재 데이터 없음)
      avgFeedCount: stats.feeding.dailyAverageCount.round(),
      avgDiapers: stats.diaper.dailyAverageCount,
      avgPlayMinutes: 0.0, // TODO: 놀이 시간 평균 (현재 데이터 없음)
      sleepTrend: sleepTrend,
      feedGapTrend: feedGapTrend,
      avgNightSleepStartHour: null, // TODO: 밤잠 시작 시간 (현재 데이터 없음)
    );
  }

  /// Sprint 19: WeeklyPattern에서 DayTimeline 리스트 생성
  List<DayTimeline> _buildWeekTimelines() {
    final pattern = _patternProvider.weeklyPattern;
    if (pattern == null) return [];

    final timelines = <DayTimeline>[];

    // WeeklyPattern.days를 사용하여 7일간의 DayTimeline 생성
    for (final dayPattern in pattern.days) {
      // DailyPattern → DayTimeline 변환
      final durationBlocks = <DurationBlock>[];
      final instantMarkers = <InstantMarker>[];

      // 연속된 수면 슬롯을 하나의 DurationBlock으로 합침
      int? sleepStartHour;
      int? sleepStartMinute;
      String? currentSleepType;

      for (final slot in dayPattern.slots) {
        final slotHour = slot.hour;
        final slotMinute = slot.halfHour * 30;

        // 수면 활동 처리
        if (slot.activity == PatternActivityType.nightSleep ||
            slot.activity == PatternActivityType.daySleep) {
          final sleepType = slot.activity == PatternActivityType.nightSleep
              ? 'nightSleep'
              : 'daySleep';

          // 새로운 수면 시작 또는 타입 변경
          if (sleepStartHour == null || currentSleepType != sleepType) {
            // 이전 수면 블록 저장
            if (sleepStartHour != null) {
              durationBlocks.add(DurationBlock(
                type: currentSleepType!,
                startTime: DateTime(
                  dayPattern.date.year,
                  dayPattern.date.month,
                  dayPattern.date.day,
                  sleepStartHour,
                  sleepStartMinute!,
                ),
                endTime: DateTime(
                  dayPattern.date.year,
                  dayPattern.date.month,
                  dayPattern.date.day,
                  slotHour,
                  slotMinute,
                ),
              ));
            }
            sleepStartHour = slotHour;
            sleepStartMinute = slotMinute;
            currentSleepType = sleepType;
          }
        } else {
          // 수면이 아닌 슬롯 - 이전 수면 블록 저장
          if (sleepStartHour != null) {
            durationBlocks.add(DurationBlock(
              type: currentSleepType!,
              startTime: DateTime(
                dayPattern.date.year,
                dayPattern.date.month,
                dayPattern.date.day,
                sleepStartHour,
                sleepStartMinute!,
              ),
              endTime: DateTime(
                dayPattern.date.year,
                dayPattern.date.month,
                dayPattern.date.day,
                slotHour,
                slotMinute,
              ),
            ));
            sleepStartHour = null;
            sleepStartMinute = null;
            currentSleepType = null;
          }
        }

        // 수유 활동 처리 (InstantMarker)
        if (slot.activity == PatternActivityType.feeding ||
            slot.overlays.contains(PatternActivityType.feeding)) {
          instantMarkers.add(InstantMarker(
            type: 'feeding',
            time: DateTime(
              dayPattern.date.year,
              dayPattern.date.month,
              dayPattern.date.day,
              slotHour,
              slotMinute,
            ),
          ));
        }

        // 기저귀 활동 처리 (InstantMarker)
        if (slot.activity == PatternActivityType.diaper ||
            slot.overlays.contains(PatternActivityType.diaper)) {
          instantMarkers.add(InstantMarker(
            type: 'diaper',
            time: DateTime(
              dayPattern.date.year,
              dayPattern.date.month,
              dayPattern.date.day,
              slotHour,
              slotMinute,
            ),
          ));
        }
      }

      // 마지막 수면 블록 저장
      if (sleepStartHour != null) {
        durationBlocks.add(DurationBlock(
          type: currentSleepType!,
          startTime: DateTime(
            dayPattern.date.year,
            dayPattern.date.month,
            dayPattern.date.day,
            sleepStartHour,
            sleepStartMinute!,
          ),
          endTime: DateTime(
            dayPattern.date.year,
            dayPattern.date.month,
            dayPattern.date.day,
            23,
            59,
          ),
        ));
      }

      timelines.add(DayTimeline(
        date: dayPattern.date,
        durationBlocks: durationBlocks,
        instantMarkers: instantMarkers,
      ));
    }

    return timelines;
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

    // Sprint 19: WeeklySummary 생성 (WeeklyGrid, WeeklyInsight용)
    final weeklySummary = _buildWeeklySummary(stats);

    // Sprint 19: WeeklyChartFull용 weekTimelines 생성
    final weekTimelines = _patternProvider.weeklyPattern != null
        ? _buildWeekTimelines()
        : <DayTimeline>[];

    return RefreshIndicator(
      onRefresh: _loadData,
      color: LuluColors.lavenderMist,
      backgroundColor: LuluColors.surfaceCard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HF3: DateNavigator (최상단, 주간 모드)
            DateNavigator(
              scope: DateScope.weekly,
              selectedDate: _selectedWeekStart,
              onDateChanged: _onWeekChanged,
              canGoNext: !_isCurrentWeek,
              onCalendarTap: () => _showWeekPicker(context),
            ),

            // Sprint 19: WeeklyGrid (1x4 요약 그리드)
            WeeklyGrid(weeklySummary: weeklySummary),

            // Sprint 19: WeeklyInsight (트렌드 한줄 요약)
            WeeklyInsight(weeklySummary: weeklySummary),

            // Sprint 19: WeeklyChartFull (실제 시간 기반 7일x24시간 차트)
            if (weekTimelines.isNotEmpty)
              WeeklyChartFull(
                weekTimelines: weekTimelines,
                weekStart: _selectedWeekStart,
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: LuluSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sprint 19: StatSummaryCard 유지 (교정연령 기준 권장범위 표시)
                  Row(
                    children: [
                      Expanded(
                        child: StatSummaryCard(
                          type: StatType.sleep,
                          value: stats.sleep.dailyAverageHours,
                          unit: l10n?.unitHours ?? '시간',
                          change: stats.sleep.changeMinutes.toDouble(),
                          correctedAgeDays: correctedAgeDays,
                        ),
                      ),
                      const SizedBox(width: LuluSpacing.sm),
                      Expanded(
                        child: StatSummaryCard(
                          type: StatType.feeding,
                          value: stats.feeding.dailyAverageCount,
                          unit: l10n?.unitTimes ?? '회',
                          change: stats.feeding.changeCount.toDouble(),
                          correctedAgeDays: correctedAgeDays,
                        ),
                      ),
                      const SizedBox(width: LuluSpacing.sm),
                      Expanded(
                        child: StatSummaryCard(
                          type: StatType.diaper,
                          value: stats.diaper.dailyAverageCount,
                          unit: l10n?.unitTimes ?? '회',
                          change: stats.diaper.changeCount.toDouble(),
                          correctedAgeDays: correctedAgeDays,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: LuluSpacing.xl),

                  // HF2-9: "주간 수면 추이" 차트 제거 (중복 정보)

                  // 주간 패턴 차트
                  if (_patternProvider.isLoading) ...[
                    const WeeklyPatternChartSkeleton(),
                    const SizedBox(height: LuluSpacing.xl),
                  ] else if (_patternProvider.weeklyPattern != null) ...[
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
                        _patternProvider.multiplePatterns.isNotEmpty) ...[
                      ..._patternProvider.multiplePatterns.map((pattern) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: LuluSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pattern.babyName,
                                style: LuluTextStyles.labelMedium.copyWith(
                                  color: LuluColors.lavenderMist,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: LuluSpacing.xs),
                              WeeklyPatternChart(
                                weeklyPattern: pattern,
                                filter: _patternProvider.filter,
                                onFilterChanged: (filter) {
                                  setState(() {
                                    _patternProvider.setFilter(filter);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ] else ...[
                      // 단일 아기 모드 - HF3: 자체 네비게이션 제거
                      WeeklyPatternChart(
                        weeklyPattern: _patternProvider.weeklyPattern!,
                        filter: _patternProvider.filter,
                        onFilterChanged: (filter) {
                          setState(() {
                            _patternProvider.setFilter(filter);
                          });
                        },
                        // HF3: 네비게이션 제거 (DateNavigator가 대체)
                        onPreviousWeek: null,
                        onNextWeek: null,
                        canGoNext: false,
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
                      l10n?.statisticsDisclaimer ?? '통계는 참고용이며 의료 조언이 아닙니다',
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
            Icons.lightbulb_outline_rounded,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: LuluColors.lavenderMist,
          ),
          const SizedBox(height: LuluSpacing.md),
          Text(
            '통계를 불러오는 중...',
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: LuluStatusColors.error,
          ),
          const SizedBox(height: LuluSpacing.md),
          Text(
            _errorMessage ?? '오류가 발생했어요',
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.primary,
            ),
          ),
          const SizedBox(height: LuluSpacing.md),
          TextButton(
            onPressed: _loadData,
            child: Text(
              '다시 시도',
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

    return Column(
      children: [
        // HF3: DateNavigator는 빈 상태에서도 표시
        DateNavigator(
          scope: DateScope.weekly,
          selectedDate: _selectedWeekStart,
          onDateChanged: _onWeekChanged,
          canGoNext: !_isCurrentWeek,
          onCalendarTap: () => _showWeekPicker(context),
        ),
        Expanded(
          child: Center(
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
                    Icons.bar_chart_rounded,
                    size: 40,
                    color: LuluColors.lavenderMist,
                  ),
                ),
                const SizedBox(height: LuluSpacing.xl),
                Text(
                  l10n?.statisticsEmptyTitle ?? '아직 통계가 없어요',
                  style: LuluTextStyles.titleMedium.copyWith(
                    color: LuluTextColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: LuluSpacing.sm),
                Text(
                  l10n?.statisticsEmptyHint ?? '기록을 쌓으면 통계가 나타나요',
                  style: LuluTextStyles.bodyMedium.copyWith(
                    color: LuluTextColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// HF6: 주간 선택 바텀시트
class _WeekPickerSheet extends StatelessWidget {
  final List<DateTime> weeks;
  final DateTime selectedWeek;
  final DateTime currentWeek;

  const _WeekPickerSheet({
    required this.weeks,
    required this.selectedWeek,
    required this.currentWeek,
  });

  String _formatWeekRange(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final startStr = DateFormat('M/d', 'ko_KR').format(weekStart);
    final endStr = DateFormat('M/d', 'ko_KR').format(weekEnd);
    return '$startStr ~ $endStr';
  }

  bool _isSameWeek(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: LuluSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들바
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: LuluSpacing.md),
            decoration: BoxDecoration(
              color: LuluTextColors.tertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 타이틀
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: LuluSpacing.lg),
            child: Text(
              '주간 선택',
              style: LuluTextStyles.titleMedium.copyWith(
                color: LuluTextColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: LuluSpacing.md),

          // 주 목록
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: weeks.length,
              itemBuilder: (context, index) {
                final week = weeks[index];
                final isSelected = _isSameWeek(week, selectedWeek);
                final isCurrent = _isSameWeek(week, currentWeek);

                return ListTile(
                  onTap: () => Navigator.of(context).pop(week),
                  selected: isSelected,
                  selectedTileColor: LuluColors.lavenderMist.withValues(alpha: 0.15),
                  leading: Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: isSelected ? LuluColors.lavenderMist : LuluTextColors.tertiary,
                    size: 24,
                  ),
                  title: Row(
                    children: [
                      Text(
                        _formatWeekRange(week),
                        style: LuluTextStyles.bodyLarge.copyWith(
                          color: isSelected ? LuluColors.lavenderMist : LuluTextColors.primary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: LuluSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: LuluSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: LuluColors.lavenderMist.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '이번 주',
                            style: LuluTextStyles.caption.copyWith(
                              color: LuluColors.lavenderMist,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
