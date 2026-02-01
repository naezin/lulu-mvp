import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/feeding_type.dart';

/// 이유식 상세 폼
///
/// 이유식 선택 시 표시되는 상세 입력 폼
/// - 음식 이름 입력
/// - 처음 먹이는 음식 체크박스
/// - 양 입력 (단위 선택: g/숟가락/그릇)
/// - 아기 반응 선택
class SolidFoodForm extends StatefulWidget {
  final String foodName;
  final bool isFirstTry;
  final SolidFoodUnit unit;
  final double amount;
  final BabyReaction? reaction;
  final ValueChanged<String> onFoodNameChanged;
  final ValueChanged<bool> onFirstTryChanged;
  final ValueChanged<SolidFoodUnit> onUnitChanged;
  final ValueChanged<double> onAmountChanged;
  final ValueChanged<BabyReaction> onReactionChanged;

  const SolidFoodForm({
    super.key,
    this.foodName = '',
    this.isFirstTry = false,
    this.unit = SolidFoodUnit.gram,
    this.amount = 0,
    this.reaction,
    required this.onFoodNameChanged,
    required this.onFirstTryChanged,
    required this.onUnitChanged,
    required this.onAmountChanged,
    required this.onReactionChanged,
  });

  @override
  State<SolidFoodForm> createState() => _SolidFoodFormState();
}

class _SolidFoodFormState extends State<SolidFoodForm> {
  late final TextEditingController _foodNameController;

  @override
  void initState() {
    super.initState();
    _foodNameController = TextEditingController(text: widget.foodName);
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    super.dispose();
  }

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
          // 헤더
          Row(
            children: [
              Icon(
                Icons.restaurant,
                size: 20,
                color: LuluActivityColors.feeding,
              ),
              const SizedBox(width: LuluSpacing.sm),
              Text(
                '이유식',
                style: LuluTextStyles.bodyLarge.copyWith(
                  color: LuluTextColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: LuluSpacing.lg),

          // 음식 이름 입력
          _buildFoodNameInput(),
          const SizedBox(height: LuluSpacing.md),

          // 처음 먹이는 음식 체크박스
          _buildFirstTryCheckbox(),
          const SizedBox(height: LuluSpacing.xl),

          // 양 입력 (단위 선택 포함)
          _buildAmountInput(),
          const SizedBox(height: LuluSpacing.xl),

          // 아기 반응
          _buildReactionSelector(),
        ],
      ),
    );
  }

  Widget _buildFoodNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '음식 이름',
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
        const SizedBox(height: LuluSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: LuluColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _foodNameController,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.primary,
            ),
            decoration: InputDecoration(
              hintText: '예: 당근 퓨레, 쌀미음',
              hintStyle: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.tertiary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: LuluSpacing.md,
                vertical: LuluSpacing.md,
              ),
            ),
            onChanged: widget.onFoodNameChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildFirstTryCheckbox() {
    return GestureDetector(
      onTap: () => widget.onFirstTryChanged(!widget.isFirstTry),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: widget.isFirstTry
                  ? LuluActivityColors.feeding
                  : LuluColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: widget.isFirstTry
                    ? LuluActivityColors.feeding
                    : LuluTextColors.tertiary,
                width: 2,
              ),
            ),
            child: widget.isFirstTry
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: LuluColors.midnightNavy,
                  )
                : null,
          ),
          const SizedBox(width: LuluSpacing.sm),
          Text(
            '처음 먹이는 음식이에요',
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.primary,
            ),
          ),
          const SizedBox(width: LuluSpacing.xs),
          Icon(
            Icons.new_releases_outlined,
            size: 16,
            color: LuluColors.champagneGold,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '양',
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
        const SizedBox(height: LuluSpacing.sm),

        // 단위 선택
        Row(
          children: SolidFoodUnit.values.map((unit) {
            final isSelected = widget.unit == unit;
            return Expanded(
              child: GestureDetector(
                onTap: () => widget.onUnitChanged(unit),
                child: Container(
                  margin: EdgeInsets.only(
                    right: unit != SolidFoodUnit.values.last
                        ? LuluSpacing.sm
                        : 0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: LuluSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? LuluActivityColors.feedingBg
                        : LuluColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? LuluActivityColors.feeding
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      unit.label,
                      style: LuluTextStyles.bodySmall.copyWith(
                        color: isSelected
                            ? LuluTextColors.primary
                            : LuluTextColors.secondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: LuluSpacing.md),

        // 양 조절
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AdjustButton(
              icon: Icons.remove,
              onTap: () {
                final step = widget.unit.step;
                final newAmount = (widget.amount - step).clamp(0.0, 1000.0);
                widget.onAmountChanged(newAmount);
              },
            ),
            const SizedBox(width: LuluSpacing.lg),
            Container(
              width: 100,
              padding: const EdgeInsets.symmetric(vertical: LuluSpacing.md),
              decoration: BoxDecoration(
                color: LuluColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${widget.amount.toInt()}${widget.unit.label}',
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
              onTap: () {
                final step = widget.unit.step;
                final newAmount = (widget.amount + step).clamp(0.0, 1000.0);
                widget.onAmountChanged(newAmount);
              },
            ),
          ],
        ),
        const SizedBox(height: LuluSpacing.md),

        // 프리셋 버튼
        _buildPresetButtons(),
      ],
    );
  }

  Widget _buildPresetButtons() {
    List<int> presets;
    switch (widget.unit) {
      case SolidFoodUnit.gram:
        presets = [30, 50, 80, 100];
      case SolidFoodUnit.spoon:
        presets = [1, 2, 3, 5];
      case SolidFoodUnit.bowl:
        presets = [1, 2, 3, 4];
    }

    return Row(
      children: presets.asMap().entries.map((entry) {
        final index = entry.key;
        final preset = entry.value;
        final isSelected = widget.amount == preset.toDouble();

        return Expanded(
          child: GestureDetector(
            onTap: () => widget.onAmountChanged(preset.toDouble()),
            child: Container(
              margin: EdgeInsets.only(
                left: index > 0 ? LuluSpacing.sm : 0,
              ),
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
                  '$preset${widget.unit.label}',
                  style: LuluTextStyles.bodySmall.copyWith(
                    color: isSelected
                        ? LuluTextColors.primary
                        : LuluTextColors.secondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReactionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '아기 반응',
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
        const SizedBox(height: LuluSpacing.sm),
        Row(
          children: BabyReaction.values.map((reaction) {
            final isSelected = widget.reaction == reaction;
            return Expanded(
              child: GestureDetector(
                onTap: () => widget.onReactionChanged(reaction),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                    right: reaction != BabyReaction.values.last
                        ? LuluSpacing.sm
                        : 0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: LuluSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? reaction.color.withValues(alpha: 0.15)
                        : LuluColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? reaction.color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        reaction.icon,
                        size: 28,
                        color: isSelected
                            ? reaction.color
                            : LuluTextColors.tertiary,
                      ),
                      const SizedBox(height: LuluSpacing.xs),
                      Text(
                        reaction.label,
                        style: LuluTextStyles.bodySmall.copyWith(
                          color: isSelected
                              ? LuluTextColors.primary
                              : LuluTextColors.secondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
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
