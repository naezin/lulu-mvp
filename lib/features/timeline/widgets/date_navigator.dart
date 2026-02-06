import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_spacing.dart';

/// 날짜/주간 범위 모드
enum DateScope {
  daily,  // 일간: "2월 5일 (목)"
  weekly, // 주간: "1/27 ~ 2/2"
}

/// HF5: 날짜/주간 네비게이터 위젯 (심플 버전)
///
/// 요구사항:
/// - 사각형 박스 제거 → 심플 화살표
/// - "오늘"/"이번 주" 버튼 제거
/// - 달력 아이콘 + 날짜 탭 → DatePicker 열림
class DateNavigator extends StatelessWidget {
  final DateScope scope;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback? onCalendarTap;
  final VoidCallback? onReset;
  final bool canGoNext;

  const DateNavigator({
    super.key,
    this.scope = DateScope.daily,
    required this.selectedDate,
    required this.onDateChanged,
    this.onCalendarTap,
    this.onReset,
    this.canGoNext = true,
  });

  bool get _canNavigateNext {
    if (!canGoNext) return false;
    final now = DateTime.now();
    if (scope == DateScope.daily) {
      final today = DateTime(now.year, now.month, now.day);
      final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      return !selected.isAfter(today.subtract(const Duration(days: 1)));
    } else {
      final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
      final normalizedCurrent = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);
      final normalizedSelected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      return normalizedCurrent != normalizedSelected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.md,
        vertical: LuluSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // HF5: 심플 화살표 (왼쪽)
          _SimpleArrowButton(
            icon: Icons.chevron_left_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              if (scope == DateScope.daily) {
                onDateChanged(selectedDate.subtract(const Duration(days: 1)));
              } else {
                onDateChanged(selectedDate.subtract(const Duration(days: 7)));
              }
            },
          ),

          const SizedBox(width: LuluSpacing.md),

          // HF5: 날짜 텍스트 + 달력 아이콘 (탭 가능)
          GestureDetector(
            onTap: onCalendarTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 20,
                  color: LuluColors.lavenderMist,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDateDisplay(),
                  style: const TextStyle(
                    color: LuluTextColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: LuluSpacing.md),

          // HF5: 심플 화살표 (오른쪽)
          _SimpleArrowButton(
            icon: Icons.chevron_right_rounded,
            onTap: _canNavigateNext
                ? () {
                    HapticFeedback.selectionClick();
                    if (scope == DateScope.daily) {
                      onDateChanged(selectedDate.add(const Duration(days: 1)));
                    } else {
                      onDateChanged(selectedDate.add(const Duration(days: 7)));
                    }
                  }
                : null,
            enabled: _canNavigateNext,
          ),
        ],
      ),
    );
  }

  String _formatDateDisplay() {
    if (scope == DateScope.daily) {
      return DateFormat('M월 d일 (E)', 'ko_KR').format(selectedDate);
    } else {
      final weekEnd = selectedDate.add(const Duration(days: 6));
      final startStr = DateFormat('M/d', 'ko_KR').format(selectedDate);
      final endStr = DateFormat('M/d', 'ko_KR').format(weekEnd);
      return '$startStr ~ $endStr';
    }
  }
}

/// HF5: 심플 화살표 버튼 (박스 없음)
class _SimpleArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _SimpleArrowButton({
    required this.icon,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 150),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: enabled ? LuluTextColors.primary : LuluTextColors.tertiary,
            size: 28,
          ),
        ),
      ),
    );
  }
}
