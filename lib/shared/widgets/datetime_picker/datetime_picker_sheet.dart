import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'lulu_datetime_picker.dart';

/// 바텀시트로 날짜/시간 피커 표시
///
/// HOTFIX v1.1: 통합 날짜/시간 피커
/// - 한 화면에서 날짜 + 시간 선택
/// - TTC < 3초 목표
///
/// 반환값: 선택된 DateTime, 취소 시 null
Future<DateTime?> showLuluDateTimePicker({
  required BuildContext context,
  required DateTime initialDateTime,
  DateTime? minimumDate,
  DateTime? maximumDate,
  String? title,
}) async {
  final l10n = S.of(context);

  final result = await showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _DateTimePickerSheet(
      initialDateTime: initialDateTime,
      minimumDate: minimumDate,
      maximumDate: maximumDate,
      title: title,
      l10n: l10n,
      onDateTimeChanged: (_) {},
    ),
  );

  return result;
}

class _DateTimePickerSheet extends StatefulWidget {
  final DateTime initialDateTime;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final String? title;
  final S? l10n;
  final ValueChanged<DateTime> onDateTimeChanged;

  const _DateTimePickerSheet({
    required this.initialDateTime,
    this.minimumDate,
    this.maximumDate,
    this.title,
    this.l10n,
    required this.onDateTimeChanged,
  });

  @override
  State<_DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<_DateTimePickerSheet> {
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;
  }

  void _onDateTimeChanged(DateTime dateTime) {
    setState(() => _selectedDateTime = dateTime);
    widget.onDateTimeChanged(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return Container(
      decoration: BoxDecoration(
        color: LuluColors.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들 바
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: LuluColors.glassBorder,
                borderRadius: BorderRadius.circular(LuluRadius.xxs),
              ),
            ),

            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n?.dateTimeCancel ?? '취소',
                      style: LuluTextStyles.labelMedium.copyWith(
                        color: LuluTextColors.secondary,
                      ),
                    ),
                  ),
                  Text(
                    widget.title ?? l10n?.dateTimePickerTitle ?? '시간 선택',
                    style: LuluTextStyles.titleSmall,
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, _selectedDateTime),
                    child: Text(
                      l10n?.dateTimeConfirm ?? '확인',
                      style: LuluTextStyles.labelMedium.copyWith(
                        color: LuluColors.lavenderMist,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 피커
            Padding(
              padding: const EdgeInsets.all(16),
              child: LuluDateTimePicker(
                initialDateTime: _selectedDateTime,
                minimumDate: widget.minimumDate,
                maximumDate: widget.maximumDate,
                minuteInterval: 1, // 1분 단위 (정확한 시간 기록)
                onDateTimeChanged: _onDateTimeChanged,
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
