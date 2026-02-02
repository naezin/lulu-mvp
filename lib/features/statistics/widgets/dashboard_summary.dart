import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/weekly_statistics.dart';
import 'summary_card.dart';

/// 대시보드 요약 위젯
///
/// 작업 지시서 v1.2.1: 대시보드 요약 (수면/수유/기저귀)
class DashboardSummary extends StatelessWidget {
  /// 주간 통계 데이터
  final WeeklyStatistics statistics;

  const DashboardSummary({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            l10n?.statisticsWeeklySummary ?? 'This Week',
            style: LuluTextStyles.titleMedium,
          ),

          const SizedBox(height: 12),

          // 요약 카드들
          Row(
            children: [
              // 수면 카드
              Expanded(
                child: SummaryCard(
                  icon: Icons.bedtime_outlined,
                  iconColor: LuluStatisticsColors.sleep,
                  label: l10n?.statisticsSleep ?? 'Sleep',
                  value: '${statistics.sleep.dailyAverageHours.toStringAsFixed(1)}h',
                  subLabel: l10n?.statisticsPerDayAverage ?? '/day',
                  change: _formatSleepChange(statistics.sleep.changeMinutes, l10n),
                  changeType: statistics.sleep.changeType,
                ),
              ),

              const SizedBox(width: 8),

              // 수유 카드
              Expanded(
                child: SummaryCard(
                  icon: Icons.local_drink_outlined,
                  iconColor: LuluStatisticsColors.feeding,
                  label: l10n?.statisticsFeeding ?? 'Feeding',
                  value: '${statistics.feeding.dailyAverageCount.toStringAsFixed(1)}회',
                  subLabel: l10n?.statisticsPerDayAverage ?? '/day',
                  change: _formatCountChange(statistics.feeding.changeCount, l10n),
                  changeType: statistics.feeding.changeType,
                ),
              ),

              const SizedBox(width: 8),

              // 기저귀 카드
              Expanded(
                child: SummaryCard(
                  icon: Icons.baby_changing_station_outlined,
                  iconColor: LuluStatisticsColors.diaper,
                  label: l10n?.statisticsDiaper ?? 'Diaper',
                  value: '${statistics.diaper.dailyAverageCount.toStringAsFixed(1)}회',
                  subLabel: l10n?.statisticsPerDayAverage ?? '/day',
                  change: _formatCountChange(statistics.diaper.changeCount, l10n),
                  changeType: statistics.diaper.changeType,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 수면 변화량 포맷
  String _formatSleepChange(int minutes, S? l10n) {
    if (minutes == 0) return l10n?.statisticsAverage ?? 'Avg';
    final absMinutes = minutes.abs();
    final sign = minutes > 0 ? '+' : '-';
    return '$sign$absMinutes분';
  }

  /// 횟수 변화량 포맷
  String _formatCountChange(int count, S? l10n) {
    if (count == 0) return l10n?.statisticsAverage ?? 'Avg';
    final sign = count > 0 ? '+' : '';
    return '$sign$count회';
  }
}
