import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';

/// 수유량/수면 시간 등 수치 입력 위젯
///
/// v2.0 변경사항:
/// - step 파라미터 추가 (기본값 10)
/// - [-step][+step] 빠른 조절 버튼 추가
/// - showAdjustButtons 옵션으로 조절 버튼 표시 제어
class AmountInput extends StatefulWidget {
  final double amount;
  final ValueChanged<double> onAmountChanged;
  final String unit;
  final List<int> presets;
  final bool compact;

  /// 빠른 조절 버튼의 증감 단위 (기본값: 10)
  final int step;

  /// 빠른 조절 버튼 표시 여부 (기본값: true)
  final bool showAdjustButtons;

  /// 최소값 (기본값: 0)
  final double minValue;

  /// 최대값 (기본값: 999)
  final double maxValue;

  const AmountInput({
    super.key,
    required this.amount,
    required this.onAmountChanged,
    this.unit = 'ml',
    this.presets = const [60, 90, 120, 150],
    this.compact = false,
    this.step = 10,
    this.showAdjustButtons = true,
    this.minValue = 0,
    this.maxValue = 999,
  });

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.amount > 0 ? widget.amount.toInt().toString() : '',
    );
  }

  @override
  void didUpdateWidget(AmountInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      final text = widget.amount > 0 ? widget.amount.toInt().toString() : '';
      if (_controller.text != text) {
        _controller.text = text;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 수량 조절 (delta만큼 증감)
  void _adjustAmount(int delta) {
    final newAmount = (widget.amount + delta).clamp(
      widget.minValue,
      widget.maxValue,
    );
    widget.onAmountChanged(newAmount);
    _controller.text = newAmount.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactInput();
    }
    return _buildFullInput();
  }

  Widget _buildFullInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 프리셋 버튼
        Row(
          children: [
            for (int i = 0; i < widget.presets.length; i++) ...[
              if (i > 0) const SizedBox(width: LuluSpacing.sm),
              Expanded(
                child: _PresetButton(
                  value: widget.presets[i],
                  unit: widget.unit,
                  isSelected: widget.amount.toInt() == widget.presets[i],
                  onTap: () {
                    widget.onAmountChanged(widget.presets[i].toDouble());
                    _controller.text = widget.presets[i].toString();
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: LuluSpacing.md),
        // 직접 입력 + 조절 버튼
        Row(
          children: [
            // [-step] 버튼
            if (widget.showAdjustButtons) ...[
              _AdjustButton(
                label: '-${widget.step}',
                onTap: () => _adjustAmount(-widget.step),
                enabled: widget.amount > widget.minValue,
              ),
              const SizedBox(width: LuluSpacing.sm),
            ],
            // 직접 입력 필드
            Expanded(child: _buildInputField()),
            // [+step] 버튼
            if (widget.showAdjustButtons) ...[
              const SizedBox(width: LuluSpacing.sm),
              _AdjustButton(
                label: '+${widget.step}',
                onTap: () => _adjustAmount(widget.step),
                enabled: widget.amount < widget.maxValue,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCompactInput() {
    return Row(
      children: [
        // 프리셋 버튼 (작게)
        for (int i = 0; i < widget.presets.length; i++) ...[
          if (i > 0) const SizedBox(width: LuluSpacing.xs),
          _CompactPresetButton(
            value: widget.presets[i],
            isSelected: widget.amount.toInt() == widget.presets[i],
            onTap: () {
              widget.onAmountChanged(widget.presets[i].toDouble());
              _controller.text = widget.presets[i].toString();
            },
          ),
        ],
        const SizedBox(width: LuluSpacing.sm),
        // 직접 입력 (축소)
        Expanded(child: _buildInputField(compact: true)),
      ],
    );
  }

  Widget _buildInputField({bool compact = false}) {
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
          : LuluSpacing.inputPadding,
      decoration: BoxDecoration(
        color: LuluColors.surfaceElevated,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              style: compact ? LuluTextStyles.bodyMedium : LuluTextStyles.bodyLarge,
              textAlign: compact ? TextAlign.center : TextAlign.start,
              decoration: InputDecoration(
                hintText: compact ? '직접' : '직접 입력',
                hintStyle: (compact ? LuluTextStyles.bodySmall : LuluTextStyles.bodyMedium)
                    .copyWith(color: LuluTextColors.tertiary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0;
                widget.onAmountChanged(amount);
              },
            ),
          ),
          Text(
            widget.unit,
            style: (compact ? LuluTextStyles.bodySmall : LuluTextStyles.bodyMedium)
                .copyWith(color: LuluTextColors.secondary),
          ),
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final int value;
  final String unit;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.value,
    required this.unit,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluActivityColors.feedingBg
              : LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          border: Border.all(
            color: isSelected
                ? LuluActivityColors.feeding
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '$value$unit',
            style: LuluTextStyles.labelMedium.copyWith(
              color: isSelected
                  ? LuluActivityColors.feeding
                  : LuluTextColors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactPresetButton extends StatelessWidget {
  final int value;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactPresetButton({
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LuluSpacing.sm,
          vertical: LuluSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluActivityColors.feedingBg
              : LuluColors.surfaceCard,
          borderRadius: BorderRadius.circular(LuluRadius.xs),
          border: Border.all(
            color: isSelected
                ? LuluActivityColors.feeding
                : Colors.transparent,
          ),
        ),
        child: Text(
          '$value',
          style: LuluTextStyles.caption.copyWith(
            color: isSelected
                ? LuluActivityColors.feeding
                : LuluTextColors.secondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// 빠른 조절 버튼 ([-10], [+10])
class _AdjustButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const _AdjustButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LuluSpacing.md,
          vertical: LuluSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: enabled
              ? LuluActivityColors.feedingBg
              : LuluColors.surfaceCard,
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          border: Border.all(
            color: enabled
                ? LuluActivityColors.feeding.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: LuluTextStyles.labelMedium.copyWith(
            color: enabled
                ? LuluActivityColors.feeding
                : LuluTextColors.tertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
