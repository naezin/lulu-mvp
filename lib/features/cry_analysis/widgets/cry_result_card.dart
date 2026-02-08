import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../models/models.dart';

/// 울음 분석 결과 카드
///
/// Phase 2: AI 울음 분석 기능
/// 분석 결과를 보여주는 메인 카드
class CryResultCard extends StatelessWidget {
  final CryAnalysisResult result;
  final String babyName;
  final VoidCallback? onActionTap;

  const CryResultCard({
    super.key,
    required this.result,
    required this.babyName,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final cryType = result.cryType;
    final isUnknown = cryType == CryType.unknown;

    return Container(
      padding: LuluSpacing.cardPadding,
      decoration: BoxDecoration(
        color: cryType.backgroundColor,
        borderRadius: BorderRadius.circular(LuluRadius.lg),
        border: Border.all(
          color: cryType.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 아이콘 + 라벨
          Row(
            children: [
              // 아이콘
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: cryType.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  cryType.icon,
                  size: 32,
                  color: cryType.color,
                ),
              ),
              const SizedBox(width: LuluSpacing.md),

              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cryType.label,
                      style: LuluTextStyles.titleLarge.copyWith(
                        color: cryType.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cryType.dunstanCode} 사운드',
                      style: LuluTextStyles.caption.copyWith(
                        color: LuluTextColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),

              // 신뢰도 표시
              _buildConfidenceBadge(),
            ],
          ),

          const SizedBox(height: LuluSpacing.lg),

          // 설명
          Text(
            cryType.description,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.secondary,
              height: 1.5,
            ),
          ),

          // 권장 행동 (Unknown이 아닐 때만)
          if (!isUnknown) ...[
            const SizedBox(height: LuluSpacing.lg),
            _buildSuggestedAction(),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge() {
    final confidence = result.confidencePercent;
    final level = result.confidenceLevel;

    Color badgeColor;
    if (result.isHighConfidence) {
      badgeColor = LuluStatusColors.success;
    } else if (result.isMediumConfidence) {
      badgeColor = LuluStatusColors.warning;
    } else {
      badgeColor = LuluTextColors.tertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.sm,
        vertical: LuluSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
      child: Column(
        children: [
          Text(
            '$confidence%',
            style: LuluTextStyles.labelLarge.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            level,
            style: LuluTextStyles.caption.copyWith(
              color: badgeColor.withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedAction() {
    final cryType = result.cryType;

    return GestureDetector(
      onTap: onActionTap,
      child: Container(
        padding: const EdgeInsets.all(LuluSpacing.md),
        decoration: BoxDecoration(
          color: cryType.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(LuluRadius.sm),
        ),
        child: Row(
          children: [
            Icon(
              LuluIcons.tip,
              size: 20,
              color: cryType.color,
            ),
            const SizedBox(width: LuluSpacing.sm),
            Expanded(
              child: Text(
                cryType.suggestedAction,
                style: LuluTextStyles.bodyMedium.copyWith(
                  color: cryType.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (cryType.relatedActivityType != null) ...[
              Icon(
                LuluIcons.forwardIos,
                size: 14,
                color: cryType.color.withValues(alpha: 0.6),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
