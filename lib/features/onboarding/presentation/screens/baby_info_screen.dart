import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/baby_type.dart';
import '../providers/onboarding_provider.dart';

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
    final babyLabel = provider.currentBabyLabel;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),

          // 질문 텍스트
          Text(
            '$babyLabel 정보를\n입력해 주세요',
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
            '이름',
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
            enableSuggestions: false,
            autocorrect: false,
            enableIMEPersonalizedLearning: false,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
            ),
            decoration: InputDecoration(
              hintText: '아기 이름을 입력하세요',
              hintStyle: const TextStyle(
                color: AppTheme.textTertiary,
              ),
              filled: true,
              fillColor: AppTheme.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
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
            '출생일',
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
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      provider.currentBaby.birthDate != null
                          ? _formatDate(provider.currentBaby.birthDate!)
                          : '출생일을 선택해주세요',
                      style: TextStyle(
                        color: provider.currentBaby.birthDate != null
                            ? AppTheme.textPrimary
                            : AppTheme.textTertiary,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today,
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
            '성별',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _GenderButton(
                  label: '남아',
                  icon: Icons.male,
                  isSelected: provider.currentBaby.gender == Gender.male,
                  onTap: () => provider.updateBabyGender(Gender.male),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GenderButton(
                  label: '여아',
                  icon: Icons.female,
                  isSelected: provider.currentBaby.gender == Gender.female,
                  onTap: () => provider.updateBabyGender(Gender.female),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // SGA-01: 출생체중 입력 (필수)
          Text(
            '출생체중',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
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
              hintText: '예: 3200',
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
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppTheme.lavenderMist,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '성장 추적 기능에 활용돼요',
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
              borderRadius: BorderRadius.circular(20),
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
                        '조산아인가요?',
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
                  '37주 미만 출생 시 교정연령으로 발달을 확인해요',
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
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                '다음',
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
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
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
              ? AppTheme.lavenderMist.withValues(alpha: 0.15)
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
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
