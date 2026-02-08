import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../shared/widgets/datetime_picker/datetime_picker_sheet.dart';

/// 기록 시간 선택 위젯
///
/// HOTFIX v1.1: 통합 날짜/시간 피커 적용
/// - 원탭으로 바텀시트 피커 표시
/// - 날짜 + 시간 한 화면에서 선택
/// - TTC < 3초 목표
class RecordTimePicker extends StatelessWidget {
  /// 라벨 텍스트
  final String label;

  /// 현재 선택된 시간
  final DateTime time;

  /// 시간 변경 콜백
  final ValueChanged<DateTime> onTimeChanged;

  /// 날짜 표시 여부
  final bool showDate;

  /// 최소 선택 가능 날짜
  final DateTime? minimumDate;

  /// 최대 선택 가능 날짜
  final DateTime? maximumDate;

  const RecordTimePicker({
    super.key,
    required this.label,
    required this.time,
    required this.onTimeChanged,
    this.showDate = true,
    this.minimumDate,
    this.maximumDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),

        // 통합 시간 선택 버튼 (HOTFIX v1.1)
        _IntegratedTimeButton(
          time: time,
          showDate: showDate,
          onTap: () => _showDateTimePicker(context),
        ),
      ],
    );
  }

  /// 통합 날짜/시간 피커 표시
  Future<void> _showDateTimePicker(BuildContext context) async {
    final result = await showLuluDateTimePicker(
      context: context,
      initialDateTime: time,
      minimumDate: minimumDate ?? DateTime.now().subtract(const Duration(days: 7)),
      maximumDate: maximumDate ?? DateTime.now(),
      title: label,
    );

    if (result != null) {
      onTimeChanged(result);
    }
  }
}

/// 통합 시간 선택 버튼 (HOTFIX v1.1)
class _IntegratedTimeButton extends StatelessWidget {
  final DateTime time;
  final bool showDate;
  final VoidCallback onTap;

  const _IntegratedTimeButton({
    required this.time,
    required this.showDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 날짜 + 시간 표시 형식
    final dateText = DateFormat('M월 d일 (E)', 'ko').format(time);
    final timeText = DateFormat('a h:mm', 'ko').format(time);
    final displayText = showDate ? '$dateText  $timeText' : timeText;

    return Semantics(
      button: true,
      label: '시간 선택: $displayText',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: LuluSpacing.lg,
            vertical: LuluSpacing.md + 4,
          ),
          decoration: BoxDecoration(
            color: LuluColors.surfaceElevated,
            borderRadius: BorderRadius.circular(LuluRadius.sm),
            border: Border.all(
              color: LuluColors.glassBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // 날짜 아이콘 + 텍스트
              if (showDate) ...[
                Icon(
                  LuluIcons.calendar,
                  size: 18,
                  color: LuluColors.lavenderMist,
                ),
                const SizedBox(width: LuluSpacing.sm),
                Text(
                  dateText,
                  style: LuluTextStyles.bodyMedium.copyWith(
                    color: LuluTextColors.primary,
                  ),
                ),
                const SizedBox(width: LuluSpacing.lg),
              ],

              // 시간 아이콘 + 텍스트
              Icon(
                LuluIcons.time,
                size: 18,
                color: LuluColors.lavenderMist,
              ),
              const SizedBox(width: LuluSpacing.sm),
              Text(
                timeText,
                style: LuluTextStyles.bodyMedium.copyWith(
                  color: LuluTextColors.primary,
                ),
              ),

              const Spacer(),

              // 화살표 아이콘
              Icon(
                LuluIcons.chevronDown,
                size: 24,
                color: LuluTextColors.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
