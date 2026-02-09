import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/lulu_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/baby_type.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/design_system/lulu_radius.dart';
import '../../../../core/design_system/lulu_icons.dart';
import 'package:intl/intl.dart';

/// Step 3: 아기 정보 입력
/// 이름, 출생일, "조산아인가요?"
class BabyInfoScreen extends StatefulWidget {
  const BabyInfoScreen({super.key});

  @override
  State<BabyInfoScreen> createState() => _BabyInfoScreenState();
}

class _BabyInfoScreenState extends State<BabyInfoScreen> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OnboardingProvider>();
      _nameController.text = provider.currentBaby.name;
      if (provider.currentBaby.birthWeightGrams != null) {
        _weightController.text = provider.currentBaby.birthWeightGrams.toString();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<OnboardingProvider>();
    if (_nameController.text != provider.currentBaby.name) {
      _nameController.text = provider.currentBaby.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final provider = context.read<OnboardingProvider>();
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: provider.currentBaby.birthDate ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.lavenderMist,
              onPrimary: AppTheme.midnightNavy,
              surface: AppTheme.surfaceCard,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      provider.updateBabyBirthDate(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final l10n = S.of(context)!;
    final babyLabel = provider.currentBabyLabel;

    // UX-04: 스크롤 시 키보드 자동 내림 + 탭하면 키보드 내림
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),

          // 질문 텍스트
          Text(
            l10n.onboardingBabyInfoTitle(babyLabel),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
          ),

          const SizedBox(height: 8),

          if (provider.babyCount > 1)
            Text(
              '${provider.currentBabyIndex + 1}/${provider.babyCount}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lavenderMist,
                  ),
            ),

          const SizedBox(height: 40),

          // 이름 입력
          Text(
            l10n.labelName,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            onChanged: provider.updateBabyName,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            // UX-04: 완료 시 키보드 내림
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            enableSuggestions: false,
            autocorrect: false,
            enableIMEPersonalizedLearning: false,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
            ),
            decoration: InputDecoration(
              hintText: l10n.hintEnterBabyName,
              hintStyle: const TextStyle(
                color: AppTheme.textTertiary,
              ),
              filled: true,
              fillColor: AppTheme.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(LuluRadius.md),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(LuluRadius.md),
                borderSide: const BorderSide(
                  color: AppTheme.lavenderMist,
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 출생일 선택
          Text(
            l10n.labelBirthDateShort,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _selectBirthDate(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(LuluRadius.md),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      provider.currentBaby.birthDate != null
                          ? DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(provider.currentBaby.birthDate!)
                          : l10n.hintSelectBirthDate,
                      style: TextStyle(
                        color: provider.currentBaby.birthDate != null
                            ? AppTheme.textPrimary
                            : AppTheme.textTertiary,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const Icon(
                    LuluIcons.calendar,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 성별 선택
          Text(
            l10n.labelGender,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _GenderButton(
                  label: l10n.genderMale,
                  icon: LuluIcons.male,
                  isSelected: provider.currentBaby.gender == Gender.male,
                  onTap: () => provider.updateBabyGender(Gender.male),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GenderButton(
                  label: l10n.genderFemale,
                  icon: LuluIcons.female,
                  isSelected: provider.currentBaby.gender == Gender.female,
                  onTap: () => provider.updateBabyGender(Gender.female),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // SGA-01: 출생체중 입력 (필수)
          Text(
            l10n.labelBirthWeightRequired,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            // UX-04: 완료 시 키보드 내림
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              if (value.isNotEmpty) {
                provider.updateBirthWeight(int.parse(value));
              } else {
                provider.clearBirthWeight();
              }
            },
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
            ),
            decoration: InputDecoration(
              hintText: l10n.hintBirthWeight,
              hintStyle: const TextStyle(
                color: AppTheme.textTertiary,
              ),
              suffixText: 'g',
              suffixStyle: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 17,
              ),
              filled: true,
              fillColor: AppTheme.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(LuluRadius.md),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(LuluRadius.md),
                borderSide: const BorderSide(
                  color: AppTheme.lavenderMist,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.birthWeightHelperText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
          ),

          const SizedBox(height: 32),

          // 조산아 여부
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(LuluRadius.lg),
              border: Border.all(
                color: provider.currentBaby.isPreterm
                    ? AppTheme.lavenderMist.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.questionIsPretermFull,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                      ),
                    ),
                    Switch.adaptive(
                      value: provider.currentBaby.isPreterm,
                      onChanged: provider.updateBabyIsPreterm,
                      thumbColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.lavenderMist;
                        }
                        return AppTheme.textSecondary;
                      }),
                      trackColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.lavenderMist.withValues(alpha: 0.3);
                        }
                        return AppTheme.surfaceElevated;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.prematureAgeInfo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
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
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),
        ],
        ),
      ),
    );
  }

}

class _GenderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluColors.lavenderLight
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(LuluRadius.md),
          border: Border.all(
            color: isSelected ? AppTheme.lavenderMist : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.lavenderGlow : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
