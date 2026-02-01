import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/feeding_type.dart';
import 'amount_input.dart';

/// 모유 수유 상세 폼
///
/// 모유 수유 시 표시되는 상세 입력 폼
/// - 방법 선택: 직접 수유 / 유축 젖병
/// - 직접 수유: 좌/우 선택 + 시간 입력
/// - 유축 젖병: 수유량 입력
class BreastFeedingForm extends StatelessWidget {
  final FeedingMethodType methodType;
  final BreastSide? breastSide;
  final int durationMinutes;
  final double amountMl;
  final List<int> recentAmounts;
  final ValueChanged<FeedingMethodType> onMethodChanged;
  final ValueChanged<BreastSide> onSideChanged;
  final ValueChanged<int> onDurationChanged;
  final ValueChanged<double> onAmountChanged;

  const BreastFeedingForm({
    super.key,
    required this.methodType,
    this.breastSide,
    this.durationMinutes = 0,
    this.amountMl = 0,
    this.recentAmounts = const [],
    required this.onMethodChanged,
    required this.onSideChanged,
    required this.onDurationChanged,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.lg),
      decoration: BoxDecoration(
        color: LuluColors.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LuluActivityColors.feeding.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (Material Icon)
          Row(
            children: [
              Icon(
                LuluIcons.feedingBreast,
                size: 20,
                color: LuluActivityColors.feeding,
              ),
              const SizedBox(width: LuluSpacing.sm),
              Text(
                '모유 수유',
                style: LuluTextStyles.bodyLarge.copyWith(
                  color: LuluTextColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: LuluSpacing.lg),

          // 방법 선택: 직접 / 유축
          Text(
            '방법 선택',
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.secondary,
            ),
          ),
          const SizedBox(height: LuluSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _MethodButton(
                  label: '직접 수유',
                  isSelected: methodType == FeedingMethodType.direct,
                  onTap: () => onMethodChanged(FeedingMethodType.direct),
                ),
              ),
              const SizedBox(width: LuluSpacing.sm),
              Expanded(
                child: _MethodButton(
                  label: '유축 젖병',
                  isSelected: methodType == FeedingMethodType.expressed,
                  onTap: () => onMethodChanged(FeedingMethodType.expressed),
                ),
              ),
            ],
          ),
          const SizedBox(height: LuluSpacing.xl),

          // 방법에 따른 상세
          if (methodType == FeedingMethodType.direct)
            _DirectDetails(
              breastSide: breastSide,
              durationMinutes: durationMinutes,
              onSideChanged: onSideChanged,
              onDurationChanged: onDurationChanged,
            )
          else
            _ExpressedDetails(
              amountMl: amountMl,
              recentAmounts: recentAmounts,
              onAmountChanged: onAmountChanged,
            ),
        ],
      ),
    );
  }
}

class _MethodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: LuluSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluActivityColors.feedingBg
              : LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? LuluActivityColors.feeding : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: isSelected
                  ? LuluTextColors.primary
                  : LuluTextColors.secondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectDetails extends StatelessWidget {
  final BreastSide? breastSide;
  final int durationMinutes;
  final ValueChanged<BreastSide> onSideChanged;
  final ValueChanged<int> onDurationChanged;

  const _DirectDetails({
    required this.breastSide,
    required this.durationMinutes,
    required this.onSideChanged,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 좌/우 선택
        Text(
          '어느 쪽?',
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
        const SizedBox(height: LuluSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _SideButton(
                label: 'L',
                subLabel: '왼쪽',
                isSelected: breastSide == BreastSide.left,
                onTap: () => onSideChanged(BreastSide.left),
              ),
            ),
            const SizedBox(width: LuluSpacing.sm),
            Expanded(
              child: _SideButton(
                label: 'R',
                subLabel: '오른쪽',
                isSelected: breastSide == BreastSide.right,
                onTap: () => onSideChanged(BreastSide.right),
              ),
            ),
            const SizedBox(width: LuluSpacing.sm),
            Expanded(
              child: _SideButton(
                label: '양쪽',
                subLabel: null,
                isSelected: breastSide == BreastSide.both,
                onTap: () => onSideChanged(BreastSide.both),
              ),
            ),
          ],
        ),
        const SizedBox(height: LuluSpacing.xl),

        // 시간 입력
        Text(
          '수유 시간',
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
        const SizedBox(height: LuluSpacing.sm),
        _DurationInput(
          duration: durationMinutes,
          onDurationChanged: onDurationChanged,
        ),
      ],
    );
  }
}

class _SideButton extends StatelessWidget {
  final String label;
  final String? subLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _SideButton({
    required this.label,
    this.subLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: LuluSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluActivityColors.feedingBg
              : LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? LuluActivityColors.feeding : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: LuluTextStyles.titleMedium.copyWith(
                color: isSelected
                    ? LuluTextColors.primary
                    : LuluTextColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subLabel != null)
              Text(
                subLabel!,
                style: LuluTextStyles.caption.copyWith(
                  color: LuluTextColors.tertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DurationInput extends StatelessWidget {
  final int duration;
  final ValueChanged<int> onDurationChanged;

  const _DurationInput({
    required this.duration,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // [-] 값 [+] 컨트롤
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AdjustButton(
              icon: Icons.remove,
              onTap: () => onDurationChanged((duration - 5).clamp(0, 60)),
            ),
            const SizedBox(width: LuluSpacing.lg),
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: LuluSpacing.md),
              decoration: BoxDecoration(
                color: LuluColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$duration분',
                  style: LuluTextStyles.titleLarge.copyWith(
                    color: LuluTextColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: LuluSpacing.lg),
            _AdjustButton(
              icon: Icons.add,
              onTap: () => onDurationChanged((duration + 5).clamp(0, 60)),
            ),
          ],
        ),
        const SizedBox(height: LuluSpacing.md),

        // 프리셋 버튼
        Row(
          children: [
            for (final preset in [5, 10, 15, 20]) ...[
              if (preset != 5) const SizedBox(width: LuluSpacing.sm),
              Expanded(
                child: _PresetButton(
                  label: '$preset분',
                  isSelected: duration == preset,
                  onTap: () => onDurationChanged(preset),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ExpressedDetails extends StatelessWidget {
  final double amountMl;
  final List<int> recentAmounts;
  final ValueChanged<double> onAmountChanged;

  const _ExpressedDetails({
    required this.amountMl,
    required this.recentAmounts,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '수유량',
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
        const SizedBox(height: LuluSpacing.sm),
        AmountInput(
          amount: amountMl,
          onAmountChanged: onAmountChanged,
          unit: 'ml',
          presets: recentAmounts.isNotEmpty ? recentAmounts : const [60, 80, 100, 120],
        ),
      ],
    );
  }
}

class _AdjustButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AdjustButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            icon,
            color: LuluActivityColors.feeding,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: LuluSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluActivityColors.feedingBg
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? LuluActivityColors.feeding
                : LuluColors.surfaceElevated,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: LuluTextStyles.bodySmall.copyWith(
              color: isSelected
                  ? LuluTextColors.primary
                  : LuluTextColors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}
