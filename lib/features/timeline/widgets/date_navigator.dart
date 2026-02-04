import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/lulu_colors.dart';

/// 날짜 좌우 탐색 위젯
///
/// 작업 지시서 v1.1: 과거 기록 접근용 (< 3초)
/// ◀ 어제 │ 오늘 │ 내일 ▶
class DateNavigator extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback? onCalendarTap;

  const DateNavigator({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.onCalendarTap,
  });

  bool get _isToday {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  bool get _isFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return selected.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 이전 날짜
          _NavButton(
            icon: Icons.chevron_left_rounded,
            label: _formatShortDate(
                selectedDate.subtract(const Duration(days: 1))),
            onTap: () =>
                onDateChanged(selectedDate.subtract(const Duration(days: 1))),
          ),

          // 현재 날짜
          GestureDetector(
            onTap: onCalendarTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDate(selectedDate),
                  style: const TextStyle(
                    color: LuluTextColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isToday)
                  const Text(
                    '오늘',
                    style: TextStyle(
                      color: LuluColors.lavenderMist,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 2),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: LuluTextColors.secondary,
                ),
              ],
            ),
          ),

          // 다음 날짜
          _NavButton(
            icon: Icons.chevron_right_rounded,
            label: _isFuture
                ? ''
                : _formatShortDate(selectedDate.add(const Duration(days: 1))),
            onTap: _isFuture
                ? null
                : () => onDateChanged(selectedDate.add(const Duration(days: 1))),
            enabled: !_isFuture,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('M월 d일 (E)', 'ko_KR').format(date);
  }

  String _formatShortDate(DateTime date) {
    return DateFormat('M/d', 'ko_KR').format(date);
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  const _NavButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onTap?.call();
            }
          : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.3,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: LuluTextColors.secondary, size: 24),
            if (label.isNotEmpty)
              Text(
                label,
                style: const TextStyle(
                  color: LuluTextColors.secondary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
