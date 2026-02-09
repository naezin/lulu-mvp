import 'package:flutter/cupertino.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import 'quick_time_buttons.dart';

/// iOS 15+ 스타일 통합 날짜/시간 피커
///
/// HOTFIX v1.1: 날짜/시간 피커 UX 개선
/// - 날짜 + 오전/오후 + 시간 통합 휠 피커
/// - Android에서도 Cupertino 스타일 유지 (일관된 UX)
/// - 빠른 조정 버튼 지원
class LuluDateTimePicker extends StatefulWidget {
  /// 초기 날짜/시간
  final DateTime initialDateTime;

  /// 날짜/시간 변경 콜백
  final ValueChanged<DateTime> onDateTimeChanged;

  /// 최소 선택 가능 날짜
  final DateTime? minimumDate;

  /// 최대 선택 가능 날짜 (기본: 현재 시간)
  final DateTime? maximumDate;

  /// 분 단위 간격 (기본: 1분 - 정확한 시간 기록)
  final int minuteInterval;

  /// 빠른 조정 버튼 표시 여부
  final bool showQuickButtons;

  const LuluDateTimePicker({
    super.key,
    required this.initialDateTime,
    required this.onDateTimeChanged,
    this.minimumDate,
    this.maximumDate,
    this.minuteInterval = 1,
    this.showQuickButtons = true,
  });

  @override
  State<LuluDateTimePicker> createState() => _LuluDateTimePickerState();
}

class _LuluDateTimePickerState extends State<LuluDateTimePicker> {
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = _normalizeDateTime(widget.initialDateTime);
  }

  @override
  void didUpdateWidget(LuluDateTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDateTime != widget.initialDateTime) {
      setState(() {
        _selectedDateTime = _normalizeDateTime(widget.initialDateTime);
      });
    }
  }

  /// minuteInterval에 맞게 시간 정규화
  DateTime _normalizeDateTime(DateTime dateTime) {
    if (widget.minuteInterval == 1) return dateTime;

    final minute = dateTime.minute;
    final normalizedMinute =
        (minute ~/ widget.minuteInterval) * widget.minuteInterval;

    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      normalizedMinute,
    );
  }

  /// 최소/최대 범위 내로 제한
  DateTime _clampDateTime(DateTime dateTime) {
    final min =
        widget.minimumDate ?? DateTime.now().subtract(const Duration(days: 7));
    final max = widget.maximumDate ?? DateTime.now();

    if (dateTime.isBefore(min)) return min;
    if (dateTime.isAfter(max)) return max;
    return dateTime;
  }

  void _updateDateTime(DateTime newDateTime) {
    final clamped = _clampDateTime(newDateTime);
    setState(() => _selectedDateTime = clamped);
    widget.onDateTimeChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMinDate =
        widget.minimumDate ?? DateTime.now().subtract(const Duration(days: 7));
    final effectiveMaxDate = widget.maximumDate ?? DateTime.now();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 통합 휠 피커
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: LuluColors.surfaceCard,
            borderRadius: BorderRadius.circular(LuluRadius.sm),
          ),
          child: CupertinoTheme(
            data: CupertinoThemeData(
              brightness: Brightness.dark,
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: TextStyle(
                  fontSize: 20,
                  color: LuluTextColors.primary,
                ),
              ),
            ),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.dateAndTime,
              initialDateTime: _selectedDateTime,
              minimumDate: effectiveMinDate,
              maximumDate: effectiveMaxDate,
              use24hFormat: false, // 오전/오후 표시
              minuteInterval: widget.minuteInterval,
              onDateTimeChanged: _updateDateTime,
            ),
          ),
        ),

        // 빠른 조정 버튼
        if (widget.showQuickButtons) ...[
          const SizedBox(height: 16),
          QuickTimeButtons(
            onTimeSelected: (DateTime newDateTime) {
              final normalized = _normalizeDateTime(newDateTime);
              _updateDateTime(normalized);
            },
          ),
        ],
      ],
    );
  }
}
