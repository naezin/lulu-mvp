import 'package:flutter/material.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';

/// 오늘 요약 카드
///
/// 수유, 수면, 기저귀 횟수를 한눈에 표시
class TodaySummaryCard extends StatelessWidget {
  final int feedingCount;
  final String sleepDuration;
  final int diaperCount;

  const TodaySummaryCard({
    super.key,
    this.feedingCount = 4,
    this.sleepDuration = '8h 30m',
    this.diaperCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.lg),
      decoration: BoxDecoration(
        color: LuluColors.deepBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 20,
                color: LuluColors.lavenderMist,
              ),
              const SizedBox(width: LuluSpacing.sm),
              Text(
                '오늘 요약',
                style: LuluTextStyles.titleMedium.copyWith(
                  color: LuluTextColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: LuluSpacing.lg),

          // 통계
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  icon: LuluIcons.feeding,
                  label: '수유',
                  value: '$feedingCount회',
                  color: LuluActivityColors.feeding,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  icon: LuluIcons.sleep,
                  label: '수면',
                  value: sleepDuration,
                  color: LuluActivityColors.sleep,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  icon: LuluIcons.diaper,
                  label: '기저귀',
                  value: '$diaperCount회',
                  color: LuluActivityColors.diaper,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: LuluSpacing.xs),
        Text(
          label,
          style: LuluTextStyles.caption.copyWith(
            color: LuluTextColors.tertiary,
          ),
        ),
        const SizedBox(height: LuluSpacing.xs),
        Text(
          value,
          style: LuluTextStyles.titleMedium.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}
