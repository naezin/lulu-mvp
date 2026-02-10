import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/lulu_colors.dart';
import '../../../../core/design_system/lulu_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart' show S;
import '../providers/onboarding_provider.dart';
import '../../../../core/design_system/lulu_radius.dart';

/// Step 2: 아기 수 선택
/// [1명] [2명] [3명] [4명+]
class BabyCountScreen extends StatelessWidget {
  const BabyCountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sprint 21 Phase 2-4: context.select for babyCount + canProceed only
    final babyCount = context.select<OnboardingProvider, int>((p) => p.babyCount);
    final canProceed = context.select<OnboardingProvider, bool>((p) => p.canProceed);
    final l10n = S.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),

          // 질문 텍스트
          Text(
            l10n.babyCountTitle,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 12),

          Text(
            l10n.babyCountSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),

          const SizedBox(height: 48),

          // 아기 수 선택 그리드
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _BabyCountCard(
                  count: 1,
                  label: l10n.babyCountOne,
                  iconCount: 1,
                  isSelected: babyCount == 1,
                  onTap: () => context.read<OnboardingProvider>().setBabyCount(1),
                ),
                _BabyCountCard(
                  count: 2,
                  label: l10n.babyTypeTwin,
                  iconCount: 2,
                  isSelected: babyCount == 2,
                  onTap: () => context.read<OnboardingProvider>().setBabyCount(2),
                ),
                _BabyCountCard(
                  count: 3,
                  label: l10n.babyTypeTriplet,
                  iconCount: 3,
                  isSelected: babyCount == 3,
                  onTap: () => context.read<OnboardingProvider>().setBabyCount(3),
                ),
                _BabyCountCard(
                  count: 4,
                  label: l10n.babyTypeQuadruplet,
                  iconCount: 4,
                  isSelected: babyCount == 4,
                  onTap: () => context.read<OnboardingProvider>().setBabyCount(4),
                ),
              ],
            ),
          ),

          // 다음 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canProceed ? () => context.read<OnboardingProvider>().nextStep() : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: AppTheme.lavenderMist,
                foregroundColor: AppTheme.midnightNavy,
                disabledBackgroundColor: AppTheme.surfaceElevated,
                disabledForegroundColor: AppTheme.textTertiary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LuluRadius.md),
                ),
              ),
              child: Text(
                l10n.buttonNext,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _BabyCountCard extends StatelessWidget {
  final int count;
  final String label;
  final int iconCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _BabyCountCard({
    required this.count,
    required this.label,
    required this.iconCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected ? AppTheme.lavenderGlow : AppTheme.textSecondary;
    final iconSize = iconCount > 2 ? 20.0 : 28.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? LuluColors.lavenderLight : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(LuluRadius.lg),
          border: Border.all(
            color: isSelected ? AppTheme.lavenderMist : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                iconCount,
                (index) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: iconCount > 2 ? 1 : 2),
                  child: Icon(
                    LuluIcons.baby,
                    size: iconSize,
                    color: iconColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isSelected ? AppTheme.lavenderGlow : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
