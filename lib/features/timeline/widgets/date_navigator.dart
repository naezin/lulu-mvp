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
/// daily: ◀ 어제 │ 2/8 (토) 오늘 📅 │ 내일 ▶
/// weekly: ◀ │ 1/27 ~ 2/2 📅 │ ▶
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Builder(
        builder: (context) {
          final l10n = S.of(context);
          final locale = Localizations.localeOf(context).languageCode;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavButton(
                icon: LuluIcons.chevronLeft,
                label: _formatShortDate(
                    selectedDate.subtract(const Duration(days: 1)), locale),
                onTap: () =>
                    onDateChanged(selectedDate.subtract(const Duration(days: 1))),
              ),
              GestureDetector(
                onTap: onCalendarTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDate(selectedDate, locale),
                      style: const TextStyle(
                        color: LuluTextColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isToday)
                      Text(
                        l10n?.today ?? 'Today',
                        style: const TextStyle(
                          color: LuluColors.lavenderMist,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 2),
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
                label: _isFuture
                    ? ''
                    : _formatShortDate(selectedDate.add(const Duration(days: 1)), locale),
                onTap: _isFuture
                    ? null
                    : () => onDateChanged(selectedDate.add(const Duration(days: 1))),
                enabled: !_isFuture,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeeklyNavigator(BuildContext context) {
    final weekEnd = selectedDate.add(const Duration(days: 6));
    final locale = Localizations.localeOf(context).languageCode;
    final dateRangeText = _formatWeekRange(selectedDate, weekEnd, locale);
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

  String _formatDate(DateTime date, String locale) {
    return DateFormat.MMMEd(locale).format(date);
  }

  String _formatShortDate(DateTime date, String locale) {
    return DateFormat.Md(locale).format(date);
  }

  String _formatWeekRange(DateTime start, DateTime end, String locale) {
    final startStr = DateFormat.Md(locale).format(start);
    final endStr = DateFormat.Md(locale).format(end);
    return '$startStr ~ $endStr';
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
