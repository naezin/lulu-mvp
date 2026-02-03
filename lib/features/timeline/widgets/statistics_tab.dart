import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../home/providers/home_provider.dart';
import '../../statistics/providers/statistics_data_provider.dart';
import '../../statistics/providers/statistics_filter_provider.dart';
import '../../statistics/models/insight_data.dart';
import 'stat_summary_card.dart';
import 'weekly_trend_chart.dart';

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
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dataProvider = StatisticsDataProvider();
    _filterProvider = StatisticsFilterProvider();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _dataProvider.dispose();
    _filterProvider.dispose();
    super.dispose();
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

      if (family == null || babies.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = '가족 정보가 없어요';
        });
        return;
      }

      final dateRange = _filterProvider.getDateRange();

      await _dataProvider.loadStatistics(
        familyId: family.id,
        babyId: selectedBabyId,
        dateRange: dateRange,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [StatisticsTab] Load error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '데이터를 불러올 수 없어요';
        });
      }
    }
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
    if (statistics == null) {
      return _buildEmptyState();
    }

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
                    value: statistics.sleep.dailyAverageHours,
                    unit: l10n?.unitHours ?? '시간',
                    change: statistics.sleep.changeMinutes.toDouble(),
                    correctedAgeDays: correctedAgeDays,
                  ),
                ),
                const SizedBox(width: LuluSpacing.sm),
                Expanded(
                  child: StatSummaryCard(
                    type: StatType.feeding,
                    value: statistics.feeding.dailyAverageCount,
                    unit: l10n?.unitTimes ?? '회',
                    change: statistics.feeding.changeCount.toDouble(),
                    correctedAgeDays: correctedAgeDays,
                  ),
                ),
                const SizedBox(width: LuluSpacing.sm),
                Expanded(
                  child: StatSummaryCard(
                    type: StatType.diaper,
                    value: statistics.diaper.dailyAverageCount,
                    unit: l10n?.unitTimes ?? '회',
                    change: statistics.diaper.changeCount.toDouble(),
                    correctedAgeDays: correctedAgeDays,
                  ),
                ),
              ],
            ),

            const SizedBox(height: LuluSpacing.xl),

            // 주간 수면 트렌드 차트
            Text(
              l10n?.weeklyTrendTitle ?? '주간 수면 추이',
              style: LuluTextStyles.titleSmall.copyWith(
                color: LuluTextColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: LuluSpacing.md),
            WeeklyTrendChart(
              dailyHours: statistics.sleep.dailyHours,
              barColor: LuluActivityColors.sleep,
              highlightIndex: _dataProvider.insight?.highlightDayIndex,
            ),

            const SizedBox(height: LuluSpacing.xl),

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
    );
  }
}
