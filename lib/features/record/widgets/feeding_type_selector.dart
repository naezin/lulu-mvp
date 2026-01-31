import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';

/// 수유 종류 선택 위젯
class FeedingTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;

  const FeedingTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  static const _feedingTypes = [
    _FeedingTypeData(
      type: 'breast',
      label: '모유',
      icon: LuluIcons.feedingBreast,
      description: '직접 수유',
    ),
    _FeedingTypeData(
      type: 'bottle',
      label: '젖병',
      icon: LuluIcons.feedingBottle,
      description: '모유/분유',
    ),
    _FeedingTypeData(
      type: 'formula',
      label: '분유',
      icon: LuluIcons.feedingBottle,
      description: '분유만',
    ),
    _FeedingTypeData(
      type: 'solid',
      label: '이유식',
      icon: LuluIcons.feedingSolid,
      description: '고형식',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '수유 종류',
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),
        Row(
          children: [
            for (int i = 0; i < _feedingTypes.length; i++) ...[
              if (i > 0) const SizedBox(width: LuluSpacing.sm),
              Expanded(
                child: _FeedingTypeButton(
                  data: _feedingTypes[i],
                  isSelected: selectedType == _feedingTypes[i].type,
                  onTap: () => onTypeChanged(_feedingTypes[i].type),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _FeedingTypeData {
  final String type;
  final String label;
  final IconData icon;
  final String description;

  const _FeedingTypeData({
    required this.type,
    required this.label,
    required this.icon,
    required this.description,
  });
}

class _FeedingTypeButton extends StatelessWidget {
  final _FeedingTypeData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _FeedingTypeButton({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: LuluSpacing.md,
          horizontal: LuluSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluActivityColors.feedingBg
              : LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? LuluActivityColors.feeding
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              data.icon,
              size: 24,
              color: isSelected
                  ? LuluActivityColors.feeding
                  : LuluTextColors.secondary,
            ),
            const SizedBox(height: LuluSpacing.xs),
            Text(
              data.label,
              style: LuluTextStyles.labelSmall.copyWith(
                color: isSelected
                    ? LuluActivityColors.feeding
                    : LuluTextColors.secondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
