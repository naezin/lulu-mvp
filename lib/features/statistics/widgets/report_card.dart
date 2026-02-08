import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/weekly_statistics.dart';
import '../models/insight_data.dart';
import 'weekly_bar_chart.dart';
import 'pie_chart_widget.dart';
import 'insight_card.dart';

/// 접이식 리포트 카드 위젯
///
/// 작업 지시서 v1.2.1: 접이식 카드, 애니메이션 300ms
class ReportCard extends StatelessWidget {
  /// 리포트 타입
  final ReportType type;

  /// 펼침 상태
  final bool isExpanded;

  /// 주간 통계 데이터
  final WeeklyStatistics statistics;

  /// 인사이트 데이터
  final InsightData? insight;

  /// 토글 콜백
  final VoidCallback onToggle;

  const ReportCard({
    super.key,
    required this.type,
    required this.isExpanded,
    required this.statistics,
    this.insight,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
        border: Border.all(color: LuluColors.glassBorder),
      ),
      child: Column(
        children: [
          // 헤더 (항상 표시)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(LuluRadius.sm),
            child: _buildHeader(context),
          ),

          // 펼침 콘텐츠
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = S.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(_getIcon(), color: _getColor(), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getTitle(l10n),
              style: LuluTextStyles.titleSmall,
            ),
          ),
          if (!isExpanded) ...[
            Text(
              _getCollapsedSummary(l10n),
              style: LuluTextStyles.bodySmall.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            color: LuluTextColors.secondary,
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case ReportType.sleep:
        return Icons.bedtime_outlined;
      case ReportType.feeding:
        return Icons.local_drink_outlined;
      case ReportType.diaper:
        return Icons.baby_changing_station_outlined;
      case ReportType.crying:
        return Icons.mic_outlined;
    }
  }

  Color _getColor() {
    switch (type) {
      case ReportType.sleep:
        return LuluStatisticsColors.sleep;
      case ReportType.feeding:
        return LuluStatisticsColors.feeding;
      case ReportType.diaper:
        return LuluStatisticsColors.diaper;
      case ReportType.crying:
        return LuluStatisticsColors.crying;
    }
  }

  String _getTitle(S? l10n) {
    switch (type) {
      case ReportType.sleep:
        return l10n?.statisticsSleepReport ?? 'Sleep Report';
      case ReportType.feeding:
        return l10n?.statisticsFeedingReport ?? 'Feeding Report';
      case ReportType.diaper:
        return l10n?.statisticsDiaperReport ?? 'Diaper Report';
      case ReportType.crying:
        return l10n?.statisticsCryingReport ?? 'Crying Report';
    }
  }

  String _getCollapsedSummary(S? l10n) {
    final perDay = l10n?.statisticsPerDayAverage ?? '/day';
    switch (type) {
      case ReportType.sleep:
        return '${statistics.sleep.dailyAverageHours.toStringAsFixed(1)}h $perDay';
      case ReportType.feeding:
        return '${statistics.feeding.dailyAverageCount.toStringAsFixed(1)}회 $perDay';
      case ReportType.diaper:
        return '${statistics.diaper.dailyAverageCount.toStringAsFixed(1)}회 $perDay';
      case ReportType.crying:
        return '이번 주 ${statistics.crying?.totalCount ?? 0}회';
    }
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // 막대차트
          WeeklyBarChart.fromReportType(
            type: type,
            data: _getDailyData(),
            height: 160,
          ),

          const SizedBox(height: 16),

          // 파이차트 + 상세 지표
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 파이차트
              _buildPieChart(),

              const SizedBox(width: 16),

              // 상세 지표
              Expanded(child: _buildDetailMetrics(context)),
            ],
          ),

          const SizedBox(height: 12),

          // 인사이트
          if (insight != null)
            InsightCard(insight: insight!, compact: true),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    switch (type) {
      case ReportType.sleep:
        return PieChartWidget.fromSleepStats(stats: statistics.sleep);
      case ReportType.feeding:
        return PieChartWidget.fromFeedingStats(stats: statistics.feeding);
      case ReportType.diaper:
        return PieChartWidget.fromDiaperStats(stats: statistics.diaper);
      case ReportType.crying:
        if (statistics.crying != null) {
          return PieChartWidget(
            sections: [
              PieSection(
                value: statistics.crying!.hungryRatio,
                label: '배고픔',
                color: LuluStatisticsColors.crying,
              ),
              PieSection(
                value: statistics.crying!.tiredRatio,
                label: '졸림',
                color: LuluStatisticsColors.crying.withValues(alpha: 0.8),
              ),
              PieSection(
                value: statistics.crying!.gasRatio,
                label: '가스',
                color: LuluStatisticsColors.crying.withValues(alpha: 0.6),
              ),
              PieSection(
                value: statistics.crying!.discomfortRatio,
                label: '불편',
                color: LuluStatisticsColors.crying.withValues(alpha: 0.4),
              ),
            ],
          );
        }
        return const SizedBox(width: 140, height: 140);
    }
  }

  Widget _buildDetailMetrics(BuildContext context) {
    switch (type) {
      case ReportType.sleep:
        return _buildMetricsList([
          _MetricItem(
            label: '낮잠',
            value: '${(statistics.sleep.napRatio * 100).toInt()}%',
          ),
          _MetricItem(
            label: '밤잠',
            value: '${(statistics.sleep.nightRatio * 100).toInt()}%',
          ),
          _MetricItem(
            label: '야간 기상',
            value: '${statistics.sleep.nightWakeups}회',
          ),
        ]);

      case ReportType.feeding:
        return _buildMetricsList([
          if (statistics.feeding.breastMilkRatio > 0)
            _MetricItem(
              label: '모유',
              value: '${(statistics.feeding.breastMilkRatio * 100).toInt()}%',
            ),
          if (statistics.feeding.formulaRatio > 0)
            _MetricItem(
              label: '분유',
              value: '${(statistics.feeding.formulaRatio * 100).toInt()}%',
            ),
          if (statistics.feeding.solidFoodRatio > 0)
            _MetricItem(
              label: '이유식',
              value: '${(statistics.feeding.solidFoodRatio * 100).toInt()}%',
            ),
        ]);

      case ReportType.diaper:
        return _buildMetricsList([
          _MetricItem(
            label: '소변',
            value: '${(statistics.diaper.wetRatio * 100).toInt()}%',
          ),
          _MetricItem(
            label: '대변',
            value: '${(statistics.diaper.dirtyRatio * 100).toInt()}%',
          ),
          _MetricItem(
            label: '혼합',
            value: '${(statistics.diaper.bothRatio * 100).toInt()}%',
          ),
        ]);

      case ReportType.crying:
        if (statistics.crying != null) {
          return _buildMetricsList([
            _MetricItem(
              label: '배고픔',
              value: '${(statistics.crying!.hungryRatio * 100).toInt()}%',
            ),
            _MetricItem(
              label: '졸림',
              value: '${(statistics.crying!.tiredRatio * 100).toInt()}%',
            ),
            _MetricItem(
              label: '가스',
              value: '${(statistics.crying!.gasRatio * 100).toInt()}%',
            ),
          ]);
        }
        return const SizedBox.shrink();
    }
  }

  Widget _buildMetricsList(List<_MetricItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.label,
                      style: LuluTextStyles.bodySmall.copyWith(
                        color: LuluTextColors.secondary,
                      ),
                    ),
                    Text(
                      item.value,
                      style: LuluTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  List<double> _getDailyData() {
    switch (type) {
      case ReportType.sleep:
        return statistics.sleep.dailyHours;
      case ReportType.feeding:
        return statistics.feeding.dailyCounts.map((e) => e.toDouble()).toList();
      case ReportType.diaper:
        return statistics.diaper.dailyCounts.map((e) => e.toDouble()).toList();
      case ReportType.crying:
        return statistics.crying?.dailyCounts.map((e) => e.toDouble()).toList() ??
            [0, 0, 0, 0, 0, 0, 0];
    }
  }
}

class _MetricItem {
  final String label;
  final String value;

  const _MetricItem({required this.label, required this.value});
}
