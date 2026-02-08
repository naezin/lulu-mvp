import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';

/// 체온 슬라이더 위젯 (UX-03)
///
/// 의료 기준 색상 구간:
/// - 35.0~36.4°C: 저체온 (파란색)
/// - 36.5~37.4°C: 정상 (초록색)
/// - 37.5~37.9°C: 미열 (주황색)
/// - 38.0°C 이상: 발열 (빨간색)
class TemperatureSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  static const double minTemp = 35.0;
  static const double maxTemp = 42.0;
  static const int divisions = 70; // 0.1°C 단위

  const TemperatureSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final status = _getTemperatureStatus(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨
        Text(
          '체온',
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.lg),

        // 큰 숫자 표시
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LuluSpacing.xl,
              vertical: LuluSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(LuluRadius.lg),
              border: Border.all(
                color: status.color.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toStringAsFixed(1),
                  style: LuluTextStyles.displayLarge.copyWith(
                    color: status.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 48,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '°C',
                    style: LuluTextStyles.titleLarge.copyWith(
                      color: status.color.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: LuluSpacing.lg),

        // 슬라이더
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: status.color,
            inactiveTrackColor: LuluColors.surfaceElevated,
            thumbColor: status.color,
            overlayColor: status.color.withValues(alpha: 0.2),
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 14,
              elevation: 4,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
          ),
          child: Slider(
            value: value.clamp(minTemp, maxTemp),
            min: minTemp,
            max: maxTemp,
            divisions: divisions,
            onChanged: (newValue) {
              // 햅틱 피드백
              HapticFeedback.selectionClick();
              onChanged(double.parse(newValue.toStringAsFixed(1)));
            },
          ),
        ),

        // 구간 레이블
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: LuluSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRangeLabel('35°', _TempRange.low),
              _buildRangeLabel('36.5°', _TempRange.normal),
              _buildRangeLabel('37.5°', _TempRange.mild),
              _buildRangeLabel('38°+', _TempRange.high),
            ],
          ),
        ),
        const SizedBox(height: LuluSpacing.lg),

        // 빠른 선택 버튼
        Row(
          children: [
            _QuickTempButton(
              label: '36.5°',
              temp: 36.5,
              currentTemp: value,
              onTap: () => onChanged(36.5),
            ),
            const SizedBox(width: LuluSpacing.sm),
            _QuickTempButton(
              label: '37.0°',
              temp: 37.0,
              currentTemp: value,
              onTap: () => onChanged(37.0),
            ),
            const SizedBox(width: LuluSpacing.sm),
            _QuickTempButton(
              label: '37.5°',
              temp: 37.5,
              currentTemp: value,
              onTap: () => onChanged(37.5),
            ),
            const SizedBox(width: LuluSpacing.sm),
            _QuickTempButton(
              label: '38.0°',
              temp: 38.0,
              currentTemp: value,
              onTap: () => onChanged(38.0),
            ),
          ],
        ),
        const SizedBox(height: LuluSpacing.lg),

        // 상태 카드
        Container(
          padding: const EdgeInsets.all(LuluSpacing.md),
          decoration: BoxDecoration(
            color: status.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(LuluRadius.sm),
            border: Border.all(
              color: status.color.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  status.icon,
                  color: status.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: LuluSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.label,
                      style: LuluTextStyles.labelLarge.copyWith(
                        color: status.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status.message,
                      style: LuluTextStyles.bodySmall.copyWith(
                        color: LuluTextColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRangeLabel(String text, _TempRange range) {
    final isActive = _getCurrentRange(value) == range;
    return Text(
      text,
      style: LuluTextStyles.caption.copyWith(
        color: isActive ? range.color : LuluTextColors.tertiary,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  _TempRange _getCurrentRange(double temp) {
    if (temp < 36.5) return _TempRange.low;
    if (temp < 37.5) return _TempRange.normal;
    if (temp < 38.0) return _TempRange.mild;
    return _TempRange.high;
  }

  _TemperatureStatus _getTemperatureStatus(double temp) {
    if (temp < 36.5) {
      return _TemperatureStatus(
        color: const Color(0xFF64B5F6), // 파란색
        label: '체온이 낮아요',
        message: '보온에 신경써주세요.',
        icon: Icons.ac_unit_rounded,
      );
    } else if (temp < 37.5) {
      return _TemperatureStatus(
        color: const Color(0xFF81C784), // 초록색
        label: '정상 체온이에요',
        message: '체온이 정상 범위입니다.',
        icon: Icons.check_circle_rounded,
      );
    } else if (temp < 38.0) {
      return _TemperatureStatus(
        color: const Color(0xFFFFB74D), // 주황색
        label: '체온이 조금 높아요',
        message: '지켜봐주세요.',
        icon: Icons.thermostat_rounded,
      );
    } else {
      return _TemperatureStatus(
        color: const Color(0xFFE57373), // 빨간색
        label: '열이 있어요',
        message: '병원 방문을 고려해주세요.',
        icon: Icons.warning_rounded,
      );
    }
  }
}

/// 체온 상태 정보
class _TemperatureStatus {
  final Color color;
  final String label;
  final String message;
  final IconData icon;

  _TemperatureStatus({
    required this.color,
    required this.label,
    required this.message,
    required this.icon,
  });
}

/// 체온 범위 enum
enum _TempRange {
  low(Color(0xFF64B5F6)),
  normal(Color(0xFF81C784)),
  mild(Color(0xFFFFB74D)),
  high(Color(0xFFE57373));

  final Color color;
  const _TempRange(this.color);
}

/// 빠른 체온 선택 버튼
class _QuickTempButton extends StatelessWidget {
  final String label;
  final double temp;
  final double currentTemp;
  final VoidCallback onTap;

  const _QuickTempButton({
    required this.label,
    required this.temp,
    required this.currentTemp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = (currentTemp - temp).abs() < 0.05;
    final color = _getColorForTemp(temp);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: LuluSpacing.md),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : LuluColors.surfaceElevated,
            borderRadius: BorderRadius.circular(LuluRadius.sm),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: LuluTextStyles.labelMedium.copyWith(
                color: isSelected ? color : LuluTextColors.secondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForTemp(double t) {
    if (t < 36.5) return const Color(0xFF64B5F6);
    if (t < 37.5) return const Color(0xFF81C784);
    if (t < 38.0) return const Color(0xFFFFB74D);
    return const Color(0xFFE57373);
  }
}
