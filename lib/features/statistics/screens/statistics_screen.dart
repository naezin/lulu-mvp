import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/weekly_statistics.dart';
import '../models/insight_data.dart';
import '../providers/statistics_data_provider.dart';
import '../providers/statistics_filter_provider.dart';
import '../providers/statistics_ui_provider.dart';
import '../widgets/baby_filter_tabs.dart';
import '../widgets/dashboard_summary.dart';
import '../widgets/weekly_bar_chart.dart';
import '../widgets/insight_card.dart';
import '../widgets/report_card.dart';
import '../widgets/together_view.dart';
import '../widgets/together_guide_dialog.dart';
import '../widgets/statistics_skeleton.dart';

/// 통계 화면
///
/// 작업 지시서 v1.2.1: 통계 메인 화면
/// SUS 85.4점, TTC 2.1초 목표
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late StatisticsFilterProvider _filterProvider;
  late StatisticsUIProvider _uiProvider;
  late StatisticsDataProvider _dataProvider;

  @override
  void initState() {
    super.initState();
    _filterProvider = StatisticsFilterProvider();
    _uiProvider = StatisticsUIProvider();
    _dataProvider = StatisticsDataProvider();

    // 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _filterProvider.dispose();
    _uiProvider.dispose();
    _dataProvider.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _uiProvider.setLoading(true);
    _uiProvider.clearError();

    try {
      final dateRange = _filterProvider.getDateRange();

      if (_filterProvider.isTogetherViewSelected) {
        // 함께 보기 데이터 로드
        await _dataProvider.loadTogetherData(
          babyIds: [], // TODO: 실제 아기 ID 목록
          dateRange: dateRange,
        );
      } else {
        // 일반 통계 데이터 로드
        String? babyId;
        if (_filterProvider.isIndividualSelected) {
          // TODO: 실제 선택된 아기 ID
          babyId = 'baby${_filterProvider.selectedBabyIndex}';
        }

        await _dataProvider.loadStatistics(
          babyId: babyId,
          dateRange: dateRange,
        );
      }
    } catch (e) {
      _uiProvider.setError('데이터를 불러올 수 없어요');
    } finally {
      _uiProvider.setLoading(false);
    }
  }

  void _onBabyFilterChanged(int index) {
    _filterProvider.selectBaby(index);

    // 함께 보기 최초 진입 시 안내 다이얼로그
    if (index == -1 && !_filterProvider.hasShownTogetherGuide) {
      _filterProvider.markTogetherGuideShown();
      showDialog(
        context: context,
        builder: (_) => const TogetherGuideDialog(),
      );
    }

    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _filterProvider),
        ChangeNotifierProvider.value(value: _uiProvider),
        ChangeNotifierProvider.value(value: _dataProvider),
      ],
      child: Scaffold(
        backgroundColor: LuluColors.surfaceDark,
        appBar: AppBar(
          backgroundColor: LuluColors.surfaceDark,
          elevation: 0,
          title: Text(
            l10n?.statisticsTitle ?? 'Statistics',
            style: LuluTextStyles.titleLarge,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                // TODO: 설정 화면 연동
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // 아기 필터 탭
            Consumer<StatisticsFilterProvider>(
              builder: (context, filter, _) {
                return BabyFilterTabs(
                  selectedIndex: filter.selectedBabyIndex,
                  babies: _buildBabyFilterItems(),
                  showCorrectedAge: true,
                  onChanged: _onBabyFilterChanged,
                );
              },
            ),

            // 오프라인 배너
            Consumer<StatisticsDataProvider>(
              builder: (context, data, _) {
                if (data.isOffline) {
                  return OfflineBanner(lastSyncTime: data.lastSyncTime);
                }
                return const SizedBox.shrink();
              },
            ),

            // 메인 콘텐츠
            Expanded(
              child: Consumer3<StatisticsFilterProvider, StatisticsUIProvider,
                  StatisticsDataProvider>(
                builder: (context, filter, ui, data, _) {
                  // 로딩 중
                  if (ui.isLoading) {
                    return const StatisticsSkeleton();
                  }

                  // 에러 상태
                  if (ui.hasError) {
                    return StatisticsErrorView(
                      message: ui.errorMessage!,
                      onRetry: _loadData,
                    );
                  }

                  // 데이터 없음
                  if (!data.hasData && !filter.isTogetherViewSelected) {
                    return StatisticsEmptyView(
                      onStartRecording: () {
                        Navigator.of(context).pop();
                      },
                    );
                  }

                  // 함께 보기 뷰
                  if (filter.isTogetherViewSelected) {
                    if (data.togetherData != null) {
                      return TogetherView(data: data.togetherData!);
                    }
                    return const StatisticsSkeleton();
                  }

                  // 일반 통계 뷰
                  return _buildNormalView(data.currentStatistics!, data.insight);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalView(WeeklyStatistics statistics, InsightData? insight) {
    final l10n = S.of(context);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 대시보드 요약
            DashboardSummary(statistics: statistics),

            const SizedBox(height: 16),

            // 주간 막대차트
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: WeeklyBarChart(
                data: statistics.sleep.dailyHours,
                barColor: LuluStatisticsColors.sleep,
                highlightIndex: insight?.highlightDayIndex,
              ),
            ),

            const SizedBox(height: 12),

            // AI 인사이트
            if (insight != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InsightCard(insight: insight),
              ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Divider(),
            ),

            // 접이식 리포트 카드들
            Consumer<StatisticsUIProvider>(
              builder: (context, ui, _) {
                return Column(
                  children: [
                    ReportCard(
                      type: ReportType.sleep,
                      isExpanded: ui.isReportExpanded(ReportType.sleep),
                      statistics: statistics,
                      insight: _getSleepInsight(statistics),
                      onToggle: () => ui.toggleReport(ReportType.sleep),
                    ),
                    ReportCard(
                      type: ReportType.feeding,
                      isExpanded: ui.isReportExpanded(ReportType.feeding),
                      statistics: statistics,
                      insight: _getFeedingInsight(statistics),
                      onToggle: () => ui.toggleReport(ReportType.feeding),
                    ),
                    ReportCard(
                      type: ReportType.diaper,
                      isExpanded: ui.isReportExpanded(ReportType.diaper),
                      statistics: statistics,
                      onToggle: () => ui.toggleReport(ReportType.diaper),
                    ),
                    if (statistics.crying != null)
                      ReportCard(
                        type: ReportType.crying,
                        isExpanded: ui.isReportExpanded(ReportType.crying),
                        statistics: statistics,
                        onToggle: () => ui.toggleReport(ReportType.crying),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // 의료 면책 문구
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    l10n?.statisticsCorrectedAgeNote ?? 'Analyzed based on corrected age',
                    style: LuluTextStyles.caption.copyWith(
                      color: LuluTextColors.tertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n?.statisticsDisclaimer ?? 'For reference only',
                    style: LuluTextStyles.caption.copyWith(
                      color: LuluTextColors.tertiary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<BabyFilterItem> _buildBabyFilterItems() {
    // TODO: FamilyProvider에서 실제 아기 목록 가져오기
    return [
      const BabyFilterItem(id: 'baby1', name: '민지', correctedAgeDays: 42),
      const BabyFilterItem(id: 'baby2', name: '민정', correctedAgeDays: 38),
    ];
  }

  InsightData? _getSleepInsight(WeeklyStatistics statistics) {
    if (statistics.sleep.changeMinutes > 30) {
      return const InsightData(
        message: '수면 패턴이 안정되고 있어요',
        type: InsightType.positive,
      );
    }
    return null;
  }

  InsightData? _getFeedingInsight(WeeklyStatistics statistics) {
    if (statistics.feeding.changeCount == 0) {
      return const InsightData(
        message: '수유 간격이 규칙적이에요',
        type: InsightType.positive,
      );
    }
    return null;
  }
}
