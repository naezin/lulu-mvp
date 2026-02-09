part of 'weekly_view.dart';

/// Week Calendar Picker (BottomSheet)
///
/// Extracted from weekly_view.dart for file size management.
/// Shows a monthly calendar where tapping a week row returns
/// that week's Monday start date.

class _WeekCalendarPickerSheet extends StatefulWidget {
  final DateTime selectedWeekStart;

  const _WeekCalendarPickerSheet({
    required this.selectedWeekStart,
  });

  @override
  State<_WeekCalendarPickerSheet> createState() =>
      _WeekCalendarPickerSheetState();
}

class _WeekCalendarPickerSheetState extends State<_WeekCalendarPickerSheet> {
  late DateTime _displayMonth;
  late DateTime _hoveredWeekStart;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(
      widget.selectedWeekStart.year,
      widget.selectedWeekStart.month,
    );
    _hoveredWeekStart = widget.selectedWeekStart;
  }

  /// Get Monday of the week containing [date]
  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Navigate months
  void _goToPreviousMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    if (nextMonth.isAfter(DateTime(now.year, now.month + 1))) return;
    setState(() {
      _displayMonth = nextMonth;
    });
  }

  /// Jump to this week
  void _goToThisWeek() {
    final now = DateTime.now();
    final thisWeekStart = _getWeekStart(now);
    Navigator.of(context).pop(thisWeekStart);
  }

  /// Build the calendar grid weeks
  List<List<DateTime>> _buildCalendarWeeks() {
    final firstDayOfMonth = DateTime(_displayMonth.year, _displayMonth.month);
    final lastDayOfMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0);

    // Start from the Monday on or before the 1st
    final calendarStart = _getWeekStart(firstDayOfMonth);

    final weeks = <List<DateTime>>[];
    var current = calendarStart;

    while (current.isBefore(lastDayOfMonth) ||
        current.month == _displayMonth.month ||
        weeks.length < 5) {
      final week = List.generate(7, (i) => current.add(Duration(days: i)));
      weeks.add(week);
      current = current.add(const Duration(days: 7));
      if (weeks.length >= 6) break;
    }

    return weeks;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(date, now);
  }

  bool _isFutureWeek(DateTime weekStart) {
    final now = DateTime.now();
    final thisWeekStart = _getWeekStart(now);
    return weekStart.isAfter(thisWeekStart);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final weeks = _buildCalendarWeeks();

    return Container(
      decoration: const BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.lg,
        vertical: LuluSpacing.md,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: LuluSpacing.md),
              decoration: BoxDecoration(
                color: LuluColors.glassBorder,
                borderRadius: BorderRadius.circular(LuluRadius.xxs),
              ),
            ),

            // Title + This Week button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.weekPickerTitle ?? 'Select Week',
                  style: LuluTextStyles.titleSmall.copyWith(
                    color: LuluTextColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: _goToThisWeek,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LuluSpacing.sm,
                      vertical: LuluSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: LuluColors.navButtonBg,
                      borderRadius: BorderRadius.circular(LuluRadius.xs),
                    ),
                    child: Text(
                      l10n?.weekPickerThisWeek ?? 'This Week',
                      style: LuluTextStyles.caption.copyWith(
                        color: LuluColors.lavenderMist,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: LuluSpacing.md),

            // Month navigator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _goToPreviousMonth,
                  child: Padding(
                    padding: const EdgeInsets.all(LuluSpacing.xs),
                    child: Icon(
                      LuluIcons.chevronLeft,
                      size: 20,
                      color: LuluTextColors.primary,
                    ),
                  ),
                ),
                Text(
                  _formatMonthYear(_displayMonth),
                  style: LuluTextStyles.bodyMedium.copyWith(
                    color: LuluTextColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: _goToNextMonth,
                  child: Padding(
                    padding: const EdgeInsets.all(LuluSpacing.xs),
                    child: Icon(
                      LuluIcons.chevronRight,
                      size: 20,
                      color: LuluTextColors.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: LuluSpacing.sm),

            // Weekday headers (Mon ~ Sun)
            _buildWeekdayHeaders(l10n),

            const SizedBox(height: LuluSpacing.xs),

            // Calendar weeks (tappable rows)
            ...weeks.map((week) => _buildWeekRow(week)),

            const SizedBox(height: LuluSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayHeaders(S? l10n) {
    final headers = [
      l10n?.weekdayMon ?? 'Mon',
      l10n?.weekdayTue ?? 'Tue',
      l10n?.weekdayWed ?? 'Wed',
      l10n?.weekdayThu ?? 'Thu',
      l10n?.weekdayFri ?? 'Fri',
      l10n?.weekdaySat ?? 'Sat',
      l10n?.weekdaySun ?? 'Sun',
    ];

    return Row(
      children: headers
          .map(
            (h) => Expanded(
              child: Center(
                child: Text(
                  h,
                  style: LuluTextStyles.caption.copyWith(
                    color: LuluTextColors.tertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildWeekRow(List<DateTime> week) {
    final weekStart = _getWeekStart(week.first);
    final isSelected = _isSameDay(weekStart, _hoveredWeekStart);
    final isFuture = _isFutureWeek(weekStart);

    return GestureDetector(
      onTap: isFuture
          ? null
          : () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop(weekStart);
            },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: isSelected ? LuluColors.weekPickerSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(LuluRadius.xs),
        ),
        padding: const EdgeInsets.symmetric(vertical: LuluSpacing.sm),
        child: Row(
          children: week.map((date) {
            final isCurrentMonth = date.month == _displayMonth.month;
            final today = _isToday(date);

            return Expanded(
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: today
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          color: LuluColors.lavenderMist,
                        )
                      : null,
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: LuluTextStyles.bodySmall.copyWith(
                      color: isFuture
                          ? LuluTextColors.tertiary
                          : today
                              ? LuluColors.midnightNavy
                              : isCurrentMonth
                                  ? LuluTextColors.primary
                                  : LuluTextColors.tertiary,
                      fontWeight: today ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatMonthYear(DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ko') {
      return '${date.year}.${date.month}';
    }
    return DateFormat.yMMMM(locale).format(date);
  }
}
