import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../data/models/growth_measurement_model.dart';

/// 성장 측정값 숫자 입력 컴포넌트
///
/// 특징:
/// - 숫자 키패드 자동 표시
/// - 소수점 자동 처리
/// - 범위 초과 시 경고
/// - 이전 값 대비 변화량 표시
class GrowthNumberInput extends StatefulWidget {
  final String label;
  final IconData icon;
  final String unit;
  final double? value;
  final double? previousValue;
  final DateTime? previousDate;
  final double min;
  final double max;
  final int decimalPlaces;
  final bool required;
  final ValueChanged<double?> onChanged;

  const GrowthNumberInput({
    super.key,
    required this.label,
    required this.icon,
    required this.unit,
    this.value,
    this.previousValue,
    this.previousDate,
    required this.min,
    required this.max,
    this.decimalPlaces = 1,
    this.required = false,
    required this.onChanged,
  });

  @override
  State<GrowthNumberInput> createState() => _GrowthNumberInputState();
}

class _GrowthNumberInputState extends State<GrowthNumberInput> {
  late TextEditingController _controller;
  String? _errorMessage;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value?.toStringAsFixed(widget.decimalPlaces) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.lg),
      decoration: BoxDecoration(
        color: LuluColors.deepBlue,
        borderRadius: BorderRadius.circular(LuluRadius.md),
        border: Border.all(
          color: _getBorderColor(),
          width: _isFocused ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 라벨
          Row(
            children: [
              Icon(widget.icon, size: 18, color: LuluColors.lavenderMist),
              const SizedBox(width: LuluSpacing.sm),
              Text(
                widget.label,
                style: LuluTextStyles.bodyLarge.copyWith(
                  color: LuluTextColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.required)
                Text(
                  ' *',
                  style: LuluTextStyles.bodyLarge.copyWith(
                    color: LuluStatusColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const Spacer(),
              Text(
                widget.required ? '필수' : '선택',
                style: LuluTextStyles.caption.copyWith(
                  color: LuluTextColors.tertiary,
                ),
              ),
            ],
          ),

          const SizedBox(height: LuluSpacing.md),

          // 입력 필드
          Row(
            children: [
              Expanded(
                child: Focus(
                  onFocusChange: (focused) {
                    setState(() => _isFocused = focused);
                  },
                  child: TextField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    style: LuluTextStyles.titleLarge.copyWith(
                      color: LuluTextColors.primary,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.0',
                      hintStyle: LuluTextStyles.titleLarge.copyWith(
                        color: LuluTextColors.tertiary,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: _onTextChanged,
                  ),
                ),
              ),
              Text(
                widget.unit,
                style: LuluTextStyles.bodyLarge.copyWith(
                  color: LuluTextColors.secondary,
                ),
              ),
            ],
          ),

          // 에러 메시지
          if (_errorMessage != null) ...[
            const SizedBox(height: LuluSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: LuluStatusColors.error,
                ),
                const SizedBox(width: LuluSpacing.xs),
                Text(
                  _errorMessage!,
                  style: LuluTextStyles.caption.copyWith(
                    color: LuluStatusColors.error,
                  ),
                ),
              ],
            ),
          ],

          // 이전 값 대비 변화량
          if (widget.previousValue != null && widget.value != null) ...[
            const SizedBox(height: LuluSpacing.md),
            _buildChangeIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildChangeIndicator() {
    final change = widget.value! - widget.previousValue!;
    final direction = change > 0.01
        ? MeasurementDirection.increasing
        : change < -0.01
            ? MeasurementDirection.decreasing
            : MeasurementDirection.stable;

    final daysAgo = widget.previousDate != null
        ? DateTime.now().difference(widget.previousDate!).inDays
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.md,
        vertical: LuluSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: LuluColors.surfaceElevated,
        borderRadius: BorderRadius.circular(LuluRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '이전: ${widget.previousValue!.toStringAsFixed(widget.decimalPlaces)}${widget.unit}',
            style: LuluTextStyles.caption.copyWith(
              color: LuluTextColors.secondary,
            ),
          ),
          if (daysAgo != null) ...[
            Text(
              ' ($daysAgo일 전)',
              style: LuluTextStyles.caption.copyWith(
                color: LuluTextColors.tertiary,
              ),
            ),
          ],
          const SizedBox(width: LuluSpacing.sm),
          Text(
            '→ ${change >= 0 ? '+' : ''}${change.toStringAsFixed(widget.decimalPlaces)}${widget.unit} ${direction.emoji}',
            style: LuluTextStyles.caption.copyWith(
              color: _getChangeColor(direction),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor() {
    if (_errorMessage != null) return LuluStatusColors.error;
    if (_isFocused) return LuluColors.lavenderMist;
    return LuluColors.surfaceElevated;
  }

  Color _getChangeColor(MeasurementDirection direction) {
    return switch (direction) {
      MeasurementDirection.increasing => LuluStatusColors.success,
      MeasurementDirection.stable => LuluTextColors.secondary,
      MeasurementDirection.decreasing => LuluStatusColors.warning,
    };
  }

  void _onTextChanged(String text) {
    if (text.isEmpty) {
      setState(() => _errorMessage = null);
      widget.onChanged(null);
      return;
    }

    final value = double.tryParse(text);
    if (value == null) {
      setState(() => _errorMessage = '올바른 숫자를 입력해주세요');
      return;
    }

    // 범위 검사
    if (value < widget.min) {
      setState(() => _errorMessage = '${widget.label}이(가) 너무 작습니다 (최소 ${widget.min}${widget.unit})');
      return;
    }
    if (value > widget.max) {
      setState(() => _errorMessage = '${widget.label}이(가) 너무 큽니다 (최대 ${widget.max}${widget.unit})');
      return;
    }

    setState(() => _errorMessage = null);
    widget.onChanged(value);
  }
}
