import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';

/// 기록 시간 선택 위젯
class RecordTimePicker extends StatelessWidget {
  final String label;
  final DateTime time;
  final ValueChanged<DateTime> onTimeChanged;
  final bool showDate;

  const RecordTimePicker({
    super.key,
    required this.label,
    required this.time,
    required this.onTimeChanged,
    this.showDate = true,
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
        Row(
          children: [
            // 날짜 선택
            if (showDate) ...[
              Expanded(
                child: _TimeButton(
                  icon: Icons.calendar_today_rounded,
                  text: DateFormat('M월 d일 (E)', 'ko').format(time),
                  onTap: () => _selectDate(context),
                ),
              ),
              const SizedBox(width: LuluSpacing.sm),
            ],
            // 시간 선택
            Expanded(
              child: _TimeButton(
                icon: Icons.access_time_rounded,
                text: DateFormat('a h:mm', 'ko').format(time),
                onTap: () => _selectTime(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: LuluSpacing.md),
        // 빠른 선택 버튼
        _QuickTimeButtons(
          currentTime: time,
          onTimeChanged: onTimeChanged,
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: time,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: LuluColors.lavenderMist,
              surface: LuluColors.deepBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      onTimeChanged(DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        time.hour,
        time.minute,
      ));
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(time),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: LuluColors.lavenderMist,
              surface: LuluColors.deepBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      onTimeChanged(DateTime(
        time.year,
        time.month,
        time.day,
        selectedTime.hour,
        selectedTime.minute,
      ));
    }
  }
}

class _TimeButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _TimeButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LuluSpacing.lg,
          vertical: LuluSpacing.md,
        ),
        decoration: BoxDecoration(
          color: LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: LuluColors.lavenderMist,
            ),
            const SizedBox(width: LuluSpacing.sm),
            Text(
              text,
              style: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTimeButtons extends StatelessWidget {
  final DateTime currentTime;
  final ValueChanged<DateTime> onTimeChanged;

  const _QuickTimeButtons({
    required this.currentTime,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Wrap(
      spacing: LuluSpacing.sm,
      runSpacing: LuluSpacing.sm,
      children: [
        _QuickButton(
          label: '지금',
          isSelected: _isWithinMinutes(currentTime, now, 1),
          onTap: () => onTimeChanged(now),
        ),
        _QuickButton(
          label: '5분 전',
          isSelected: _isWithinMinutes(
            currentTime,
            now.subtract(const Duration(minutes: 5)),
            1,
          ),
          onTap: () => onTimeChanged(
            now.subtract(const Duration(minutes: 5)),
          ),
        ),
        _QuickButton(
          label: '15분 전',
          isSelected: _isWithinMinutes(
            currentTime,
            now.subtract(const Duration(minutes: 15)),
            1,
          ),
          onTap: () => onTimeChanged(
            now.subtract(const Duration(minutes: 15)),
          ),
        ),
        _QuickButton(
          label: '30분 전',
          isSelected: _isWithinMinutes(
            currentTime,
            now.subtract(const Duration(minutes: 30)),
            1,
          ),
          onTap: () => onTimeChanged(
            now.subtract(const Duration(minutes: 30)),
          ),
        ),
        _QuickButton(
          label: '1시간 전',
          isSelected: _isWithinMinutes(
            currentTime,
            now.subtract(const Duration(hours: 1)),
            1,
          ),
          onTap: () => onTimeChanged(
            now.subtract(const Duration(hours: 1)),
          ),
        ),
      ],
    );
  }

  bool _isWithinMinutes(DateTime time1, DateTime time2, int minutes) {
    return time1.difference(time2).inMinutes.abs() <= minutes;
  }
}

class _QuickButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LuluSpacing.md,
          vertical: LuluSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluColors.lavenderMist.withValues(alpha: 0.15)
              : LuluColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? LuluColors.lavenderMist : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: LuluTextStyles.caption.copyWith(
            color: isSelected ? LuluColors.lavenderMist : LuluTextColors.secondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
