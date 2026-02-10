import 'package:flutter/material.dart';

import '../../core/design_system/lulu_colors.dart';
import '../../core/design_system/lulu_icons.dart';
import '../../core/design_system/lulu_radius.dart';
import '../../core/design_system/lulu_spacing.dart';
import '../../core/design_system/lulu_typography.dart';
import '../../l10n/generated/app_localizations.dart' show S;

/// Phase 2 울음 분석 예약 영역 (Sprint 6 Day 2)
///
/// MVP-F에서는 Placeholder로 표시
/// Phase 2에서 실제 울음 분석 기능으로 교체 예정
class CryAnalysisPlaceholder extends StatelessWidget {
  /// 터치 시 콜백 (Phase 2 예고 다이얼로그 등)
  final VoidCallback? onTap;

  const CryAnalysisPlaceholder({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showComingSoonDialog(context),
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(
          horizontal: LuluSpacing.lg,
          vertical: LuluSpacing.md,
        ),
        decoration: BoxDecoration(
          color: LuluColors.lavenderSubtle,
          borderRadius: BorderRadius.circular(LuluRadius.md),
          border: Border.all(
            color: LuluColors.lavenderSelected,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: LuluColors.lavenderLight,
                borderRadius: BorderRadius.circular(LuluRadius.sm),
              ),
              child: Center(
                child: Icon(
                  LuluIcons.soundWave,
                  size: 24,
                  color: LuluColors.lavenderMist,
                ),
              ),
            ),
            const SizedBox(width: LuluSpacing.md),
            // 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    S.of(context)!.cryAnalysisPreparing,
                    style: LuluTextStyles.bodyMedium.copyWith(
                      color: LuluTextColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    S.of(context)!.cryAnalysisComingSoon,
                    style: LuluTextStyles.caption.copyWith(
                      color: LuluTextColors.tertiary,
                    ),
                  ),
                ],
              ),
            ),
            // Coming Soon 배지
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: LuluSpacing.sm,
                vertical: LuluSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: LuluColors.lavenderSelected,
                borderRadius: BorderRadius.circular(LuluRadius.xs),
              ),
              child: Text(
                S.of(context)!.comingSoonBadge,
                style: LuluTextStyles.caption.copyWith(
                  color: LuluColors.lavenderMist,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LuluColors.deepBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuluRadius.lg),
        ),
        title: Row(
          children: [
            Icon(LuluIcons.soundWave, size: 28, color: LuluColors.lavenderMist),
            const SizedBox(width: LuluSpacing.sm),
            Text(
              S.of(context)!.cryAnalysisTitle,
              style: LuluTextStyles.titleMedium.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
          ],
        ),
        content: Text(
          S.of(context)!.cryAnalysisDetailedDescription,
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              S.of(context)!.buttonConfirm,
              style: LuluTextStyles.labelMedium.copyWith(
                color: LuluColors.lavenderMist,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
