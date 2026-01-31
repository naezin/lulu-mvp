import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/utils/sga_calculator.dart';
import '../../../data/models/baby_model.dart';

/// SGA-01: 아기 상태 뱃지 위젯
///
/// 조산아: 교정연령 표시
/// SGA: "성장 추적 모드" 뱃지
/// 만삭 정상: 뱃지 없음
class BabyStatusBadge extends StatelessWidget {
  final BabyModel baby;

  const BabyStatusBadge({super.key, required this.baby});

  @override
  Widget build(BuildContext context) {
    final badgeText = baby.statusBadgeText;
    if (badgeText == null) return const SizedBox.shrink();

    final badgeColor = baby.statusBadgeColor ?? LuluColors.softBlue;
    final isSGA = baby.birthClassification == BirthClassification.fullTermSGA;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.sm,
        vertical: LuluSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSGA) ...[
            Icon(
              Icons.trending_up_rounded,
              size: 14,
              color: badgeColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            badgeText,
            style: LuluTextStyles.caption.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
