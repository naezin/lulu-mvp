import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';

/// Step 4: 조산아 정보 입력 (조건부)
/// 출생주수, 출생체중
class PretermInfoScreen extends StatefulWidget {
  const PretermInfoScreen({super.key});

  @override
  State<PretermInfoScreen> createState() => _PretermInfoScreenState();
}

class _PretermInfoScreenState extends State<PretermInfoScreen> {
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OnboardingProvider>();
      if (provider.currentBaby.birthWeightGrams != null) {
        _weightController.text = provider.currentBaby.birthWeightGrams.toString();
      }
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
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
            '$babyLabel의 출생 정보를\n입력해 주세요',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
          ),

          const SizedBox(height: 12),

          Text(
            '교정연령 계산에 사용돼요',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),

          const SizedBox(height: 48),

          // 출생 주수 선택
          Text(
            '출생 주수',
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

          // 출생 체중 입력
          Text(
            '출생 체중 (선택)',
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
              }
            },
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
            ),
            decoration: InputDecoration(
              hintText: '예: 2500',
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

          const SizedBox(height: 32),

          // 교정연령 설명 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.infoSoft.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.infoSoft.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.infoSoft,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '교정연령이란?',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '만삭 예정일을 기준으로 계산한 나이예요. 조산아의 발달을 더 정확하게 평가할 수 있어요.',
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
    return Column(
      children: [
        // 현재 선택된 주수 표시
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
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
                '주',
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
            overlayColor: AppTheme.lavenderMist.withValues(alpha: 0.2),
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
                '22주',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
              ),
              Text(
                '37주 미만 = 조산',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.warningSoft,
                    ),
              ),
              Text(
                '42주',
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
