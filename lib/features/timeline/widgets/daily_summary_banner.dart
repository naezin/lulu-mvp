import 'package:flutter/material.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_type.dart';

/// 일간 요약 배너 위젯
///
/// 작업 지시서 v1.1: 수유 N회 · 수면 Nh · 기저귀 N회
class DailySummaryBanner extends StatelessWidget {
  final List<ActivityModel> activities;

  const DailySummaryBanner({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final feedingCount = activities.where((a) => a.type == ActivityType.feeding).length;
    final diaperCount = activities.where((a) => a.type == ActivityType.diaper).length;
    final sleepHours = _calculateSleepHours();
    final totalFeedingMl = _calculateTotalFeedingMl();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: LuluColors.lavenderMist.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: LuluColors.lavenderMist.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItemWithIcon(
            icon: LuluIcons.feeding,
            color: LuluActivityColors.feeding,
            value: feedingCount > 0 && totalFeedingMl > 0
                ? '$feedingCount회 ${totalFeedingMl.toInt()}ml'
                : '$feedingCount회',
            label: '수유',
          ),
          _buildDivider(),
          _buildSummaryItemWithIcon(
            icon: LuluIcons.sleep,
            color: LuluActivityColors.sleep,
            value: '${sleepHours.toStringAsFixed(1)}h',
            label: '수면',
          ),
          _buildDivider(),
          _buildSummaryItemWithIcon(
            icon: LuluIcons.diaper,
            color: LuluActivityColors.diaper,
            value: '$diaperCount회',
            label: '기저귀',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItemWithIcon({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: LuluTextColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: LuluTextColors.secondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      color: LuluTextColors.tertiary.withValues(alpha: 0.3),
    );
  }

  double _calculateSleepHours() {
    double totalMinutes = 0;
    for (final activity in activities) {
      if (activity.type == ActivityType.sleep && activity.durationMinutes != null) {
        totalMinutes += activity.durationMinutes!;
      }
    }
    return totalMinutes / 60;
  }

  double _calculateTotalFeedingMl() {
    double totalMl = 0;
    for (final activity in activities) {
      if (activity.type == ActivityType.feeding) {
        final amount = activity.data?['amount_ml'] as num?;
        if (amount != null) {
          totalMl += amount.toDouble();
        }
      }
    }
    return totalMl;
  }
}
