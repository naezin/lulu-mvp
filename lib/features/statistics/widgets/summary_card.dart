import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../models/weekly_statistics.dart';

/// 요약 카드 위젯
///
/// 작업 지시서 v1.2.1: 대시보드 개별 요약 카드
class SummaryCard extends StatelessWidget {
  /// 아이콘
  final IconData icon;

  /// 아이콘 색상
  final Color iconColor;

  /// 레이블 (예: "수면")
  final String label;

  /// 값 (예: "14.2h")
  final String value;

  /// 서브레이블 (예: "/일 평균")
  final String subLabel;

  /// 변화량 (예: "+30분", "평균", "-1회")
  final String change;

  /// 변화 유형
  final ChangeType changeType;

  const SummaryCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subLabel,
    required this.change,
    required this.changeType,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value $subLabel, 지난주 대비 $change',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: LuluColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LuluColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘 + 레이블
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: LuluTextStyles.caption.copyWith(
                    color: LuluTextColors.secondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 값
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: LuluTextStyles.titleMedium.copyWith(
                    color: LuluTextColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  subLabel,
                  style: LuluTextStyles.caption.copyWith(
                    color: LuluTextColors.tertiary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // 변화량
            _buildChangeIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeIndicator() {
    Color color;
    IconData? changeIcon;

    switch (changeType) {
      case ChangeType.increase:
        color = LuluStatisticsColors.increase;
        changeIcon = Icons.arrow_upward;
      case ChangeType.decrease:
        color = LuluStatisticsColors.decrease;
        changeIcon = Icons.arrow_downward;
      case ChangeType.neutral:
        color = LuluStatisticsColors.neutral;
        changeIcon = null;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (changeIcon != null) ...[
          Icon(changeIcon, size: 12, color: color),
          const SizedBox(width: 2),
        ],
        Text(
          change,
          style: LuluTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

