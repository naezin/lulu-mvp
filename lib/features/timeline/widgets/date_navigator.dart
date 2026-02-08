import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// DateNavigator scope: daily or weekly
enum DateNavigatorScope { daily, weekly }

/// 날짜 좌우 탐색 위젯
///
/// daily: ◀ │ 2/8 (일) 📅 │ ▶
/// weekly: ◀ │ 2/2 ~ 2/8 📅 │ ▶
class DateNavigator extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback? onCalendarTap;

  /// daily (default) or weekly
  final DateNavigatorScope scope;

  /// Weekly mode: whether next week button is enabled
  final bool canGoNext;

  const DateNavigator({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.onCalendarTap,
    this.scope = DateNavigatorScope.daily,
    this.canGoNext = true,
  });

  bool get _isFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return selected.isAfter(today);
  }

  /// Weekly: check if the selected week contains today
  bool get _isCurrentWeek {
    final now = DateTime.now();
    final weekEnd = selectedDate.add(const Duration(days: 6));
    final today = DateTime(now.year, now.month, now.day);
    final weekStartNorm = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return !today.isBefore(weekStartNorm) && !today.isAfter(weekEnd);
  }

  @override
  Widget build(BuildContext context) {
    if (scope == DateNavigatorScope.weekly) {
      return _buildWeeklyNavigator(context);
    }
    return _buildDailyNavigator(context);
  }

  Widget _buildDailyNavigator(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = S.of(context);
    final nextEnabled = !_isFuture;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(
            icon: LuluIcons.chevronLeft,
            label: '',
            onTap: () =>
                onDateChanged(selectedDate.subtract(const Duration(days: 1))),
          ),
          GestureDetector(
            onTap: onCalendarTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDate(selectedDate, locale, l10n),
                  style: const TextStyle(
                    color: LuluTextColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  LuluIcons.calendar,
                  size: 16,
                  color: LuluTextColors.secondary,
                ),
              ],
            ),
          ),
          _NavButton(
            icon: LuluIcons.chevronRight,
            label: '',
            onTap: nextEnabled
                ? () => onDateChanged(selectedDate.add(const Duration(days: 1)))
                : null,
            enabled: nextEnabled,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyNavigator(BuildContext context) {
    final weekEnd = selectedDate.add(const Duration(days: 6));
    final l10n = S.of(context);
    final dateRangeText = _formatWeekRange(selectedDate, weekEnd, l10n);
    final nextEnabled = canGoNext && !_isCurrentWeek;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(
            icon: LuluIcons.chevronLeft,
            label: '',
            onTap: () =>
                onDateChanged(selectedDate.subtract(const Duration(days: 7))),
          ),
          GestureDetector(
            onTap: onCalendarTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateRangeText,
                  style: const TextStyle(
                    color: LuluTextColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  LuluIcons.calendar,
                  size: 16,
                  color: LuluTextColors.secondary,
                ),
              ],
            ),
          ),
          _NavButton(
            icon: LuluIcons.chevronRight,
            label: '',
            onTap: nextEnabled
                ? () => onDateChanged(selectedDate.add(const Duration(days: 7)))
                : null,
            enabled: nextEnabled,
          ),
        ],
      ),
    );
  }

  /// daily: M/d (E) → 2/8 (일) or 2/8 (Sun)
  String _formatDate(DateTime date, String locale, S? l10n) {
    final weekday = DateFormat.E(locale).format(date);
    if (l10n != null) {
      return l10n.dateFormatDaily(
        '${date.month}',
        '${date.day}',
        weekday,
      );
    }
    return '${date.month}/${date.day} ($weekday)';
  }

  /// weekly: M/d ~ M/d → 2/2 ~ 2/8
  String _formatWeekRange(DateTime start, DateTime end, S? l10n) {
    if (l10n != null) {
      return l10n.dateFormatWeeklyRange(
        '${start.month}',
        '${start.day}',
        '${end.month}',
        '${end.day}',
      );
    }
    return '${start.month}/${start.day} ~ ${end.month}/${end.day}';
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
