import 'package:flutter/material.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// 성장 화면 Empty 상태 (측정 기록 없음)
///
/// 긍정적 메시지와 함께 첫 기록 유도
class GrowthEmptyState extends StatelessWidget {
  final String? babyName;
  final VoidCallback onAddRecord;

  const GrowthEmptyState({
    super.key,
    this.babyName,
    required this.onAddRecord,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LuluSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이콘
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: LuluColors.lavenderLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(LuluIcons.ruler, size: 40, color: LuluColors.lavenderMist),
              ),
            ),

            const SizedBox(height: LuluSpacing.xl),

            // 메시지
            Text(
              babyName != null
                  ? l10n.growthEmptyTitleWithName(babyName!)
                  : l10n.growthEmptyTitle,
              style: LuluTextStyles.titleMedium.copyWith(
                color: LuluTextColors.primary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: LuluSpacing.md),

            Text(
              l10n.growthEmptyDescription,
              style: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: LuluSpacing.xxl),

            // CTA 버튼
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: onAddRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LuluColors.lavenderMist,
                  foregroundColor: LuluColors.midnightNavy,
                  padding: const EdgeInsets.symmetric(
                    vertical: LuluSpacing.md,
                    horizontal: LuluSpacing.lg,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(LuluRadius.xl),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LuluIcons.memo, size: 18, color: LuluColors.midnightNavy),
                    const SizedBox(width: LuluSpacing.sm),
                    Text(
                      l10n.growthEmptyButton,
                      style: LuluTextStyles.bodyMedium.copyWith(
                        color: LuluColors.midnightNavy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
