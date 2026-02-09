import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/design_system/lulu_colors.dart';
import '../../../../core/design_system/lulu_radius.dart';
import '../../../../core/design_system/lulu_icons.dart';
import '../../../../l10n/generated/app_localizations.dart' show S;

/// Step 4: 조산아 정보 입력 (조건부)
/// 출생주수만 입력 (출생체중은 baby_info_screen에서 이미 필수로 입력받음)
class PretermInfoScreen extends StatefulWidget {
  const PretermInfoScreen({super.key});

  @override
  State<PretermInfoScreen> createState() => _PretermInfoScreenState();
}

class _PretermInfoScreenState extends State<PretermInfoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OnboardingProvider>();

      // BUGFIX: gestationalWeeks 초기값 설정 (슬라이더 기본값 32주)
      // 슬라이더는 32주로 표시되지만, 실제 값이 null이면 버튼이 비활성화됨
      if (provider.currentBaby.gestationalWeeks == null) {
        provider.updateGestationalWeeks(32);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final l10n = S.of(context)!;
    final babyLabel = provider.currentBabyLabel(l10n);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),

          // 질문 텍스트
          Text(
            l10n.pretermInfoTitle(babyLabel),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
          ),

          const SizedBox(height: 12),

          Text(
            l10n.pretermInfoSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),

          const SizedBox(height: 48),

          // 출생 주수 선택
          Text(
            l10n.pretermGestationalWeeksLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 12),

          // 주수 선택 슬라이더
          _WeeksSelector(
            selectedWeeks: provider.currentBaby.gestationalWeeks ?? 32,
            onChanged: provider.updateGestationalWeeks,
          ),

          const SizedBox(height: 32),

          // 교정연령 설명 카드
          // NOTE: 출생 체중은 baby_info_screen에서 이미 필수로 입력받으므로 제거
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.infoSoft.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(LuluRadius.lg),
              border: Border.all(
                color: AppTheme.infoSoft.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LuluIcons.infoOutline,
                  color: AppTheme.infoSoft,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.pretermCorrectedAgeTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.pretermCorrectedAgeDesc,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // 다음 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.canProceed ? () => provider.nextStep() : null,
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

class _WeeksSelector extends StatelessWidget {
  final int selectedWeeks;
  final ValueChanged<int> onChanged;

  const _WeeksSelector({
    required this.selectedWeeks,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;

    return Column(
      children: [
        // 현재 선택된 주수 표시
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(LuluRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$selectedWeeks',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.lavenderMist,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.pretermWeeksUnit,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 슬라이더
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppTheme.lavenderMist,
            inactiveTrackColor: AppTheme.surfaceElevated,
            thumbColor: AppTheme.lavenderMist,
            overlayColor: LuluColors.lavenderSelected,
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: selectedWeeks.toDouble(),
            min: 22,
            max: 42,
            divisions: 20,
            onChanged: (value) => onChanged(value.round()),
          ),
        ),

        // 범위 라벨
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.pretermWeeksMin,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
              ),
              Text(
                l10n.pretermWeeksPreterm,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.warningSoft,
                    ),
              ),
              Text(
                l10n.pretermWeeksMax,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
