import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_type.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../shared/widgets/datetime_picker/datetime_picker_sheet.dart';

/// 활동 수정 바텀시트
///
/// 작업 지시서 v1.1: 수정 바텀시트
/// - 시간 변경 (DateTimePicker)
/// - 타입별 데이터 수정
/// - 메모 수정
/// - 저장/취소 버튼
class EditActivitySheet extends StatefulWidget {
  final ActivityModel activity;

  const EditActivitySheet({
    super.key,
    required this.activity,
  });

  /// 바텀시트 표시 헬퍼
  static Future<ActivityModel?> show(
    BuildContext context, {
    required ActivityModel activity,
  }) {
    return showModalBottomSheet<ActivityModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditActivitySheet(activity: activity),
    );
  }

  @override
  State<EditActivitySheet> createState() => _EditActivitySheetState();
}

class _EditActivitySheetState extends State<EditActivitySheet> {
  final ActivityRepository _activityRepository = ActivityRepository();
  final _notesController = TextEditingController();

  late DateTime _startTime;
  late DateTime? _endTime;
  late Map<String, dynamic> _data;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTime = widget.activity.startTime;
    _endTime = widget.activity.endTime;
    _data = Map<String, dynamic>.from(widget.activity.data ?? {});
    _notesController.text = widget.activity.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: LuluColors.midnightNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          _buildDragHandle(),

          // 헤더
          _buildHeader(),

          const Divider(color: LuluColors.glassBorder, height: 1),

          // 콘텐츠
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: LuluSpacing.lg,
                right: LuluSpacing.lg,
                top: LuluSpacing.lg,
                bottom: LuluSpacing.lg + bottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 시간 수정
                  _buildTimeSection(),

                  const SizedBox(height: LuluSpacing.xl),

                  // 타입별 데이터 수정
                  _buildTypeSpecificSection(),

                  const SizedBox(height: LuluSpacing.xl),

                  // 메모 수정
                  _buildNotesSection(),

                  // 에러 메시지
                  if (_errorMessage != null) ...[
                    const SizedBox(height: LuluSpacing.md),
                    _buildErrorMessage(_errorMessage!),
                  ],

                  const SizedBox(height: LuluSpacing.xl),

                  // 저장 버튼
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: LuluTextColors.tertiary.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final emoji = _getActivityEmoji(widget.activity.type);
    final title = _getActivityTitle(widget.activity.type);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.lg,
        vertical: LuluSpacing.md,
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: LuluSpacing.sm),
          Text(
            '$title 수정',
            style: LuluTextStyles.titleMedium.copyWith(
              color: LuluTextColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: LuluTextColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '시간',
          style: LuluTextStyles.labelLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),

        // 시작 시간
        _buildTimeButton(
          label: '시작',
          time: _startTime,
          onTap: () => _selectTime(isStart: true),
        ),

        // 종료 시간 (수면 타입인 경우)
        if (widget.activity.type == ActivityType.sleep) ...[
          const SizedBox(height: LuluSpacing.sm),
          _buildTimeButton(
            label: '종료',
            time: _endTime,
            onTap: () => _selectTime(isStart: false),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeButton({
    required String label,
    required DateTime? time,
    required VoidCallback onTap,
  }) {
    final displayText = time != null
        ? DateFormat('M월 d일 (E)  a h:mm', 'ko_KR').format(time)
        : '설정 안 함';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(LuluSpacing.md),
        decoration: BoxDecoration(
          color: LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LuluColors.glassBorder),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),
            const SizedBox(width: LuluSpacing.md),
            Expanded(
              child: Text(
                displayText,
                style: LuluTextStyles.bodyMedium.copyWith(
                  color: LuluTextColors.primary,
                ),
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: LuluSpacing.sm),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: LuluTextColors.tertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificSection() {
    switch (widget.activity.type) {
      case ActivityType.feeding:
        return _buildFeedingSection();
      case ActivityType.sleep:
        return const SizedBox.shrink(); // 수면은 시간만
      case ActivityType.diaper:
        return _buildDiaperSection();
      case ActivityType.play:
        return _buildPlaySection();
      case ActivityType.health:
        return _buildHealthSection();
    }
  }

  Widget _buildFeedingSection() {
    final amountMl = (_data['amount_ml'] as num?)?.toDouble() ?? 0;
    final feedingType = _data['feeding_type'] as String? ?? 'bottle';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '수유 정보',
          style: LuluTextStyles.labelLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),

        // 수유 타입
        _buildChipSelector(
          label: '종류',
          options: const ['breast', 'formula', 'bottle'],
          displayLabels: const ['모유', '분유', '젖병'],
          selectedValue: feedingType,
          onChanged: (value) => setState(() => _data['feeding_type'] = value),
        ),

        const SizedBox(height: LuluSpacing.md),

        // 수유량 (분유/젖병인 경우)
        if (feedingType != 'breast') ...[
          _buildAmountInput(
            label: '수유량',
            value: amountMl,
            unit: 'ml',
            presets: const [60, 90, 120, 150],
            onChanged: (value) => setState(() => _data['amount_ml'] = value),
          ),
        ],
      ],
    );
  }

  Widget _buildDiaperSection() {
    final diaperType = _data['diaper_type'] as String? ?? 'wet';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기저귀 정보',
          style: LuluTextStyles.labelLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),

        _buildChipSelector(
          label: '종류',
          options: const ['wet', 'dirty', 'both', 'dry'],
          displayLabels: const ['소변', '대변', '소변+대변', '건조'],
          selectedValue: diaperType,
          onChanged: (value) => setState(() => _data['diaper_type'] = value),
        ),
      ],
    );
  }

  Widget _buildPlaySection() {
    final playType = _data['play_type'] as String? ?? '놀이';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '놀이 정보',
          style: LuluTextStyles.labelLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),

        _buildChipSelector(
          label: '종류',
          options: const ['터미타임', '목욕', '외출', '놀이', '독서', '기타'],
          displayLabels: const ['터미타임', '목욕', '외출', '놀이', '독서', '기타'],
          selectedValue: playType,
          onChanged: (value) => setState(() => _data['play_type'] = value),
        ),
      ],
    );
  }

  Widget _buildHealthSection() {
    final temperature = (_data['temperature'] as num?)?.toDouble() ?? 36.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '건강 정보',
          style: LuluTextStyles.labelLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),

        _buildAmountInput(
          label: '체온',
          value: temperature,
          unit: '°C',
          presets: const [],
          step: 0.1,
          minValue: 34.0,
          maxValue: 42.0,
          onChanged: (value) => setState(() => _data['temperature'] = value),
        ),
      ],
    );
  }

  Widget _buildChipSelector({
    required String label,
    required List<String> options,
    required List<String> displayLabels,
    required String selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    return Wrap(
      spacing: LuluSpacing.sm,
      runSpacing: LuluSpacing.sm,
      children: [
        for (int i = 0; i < options.length; i++)
          GestureDetector(
            onTap: () => onChanged(options[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: LuluSpacing.md,
                vertical: LuluSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: selectedValue == options[i]
                    ? LuluColors.lavenderMist.withValues(alpha: 0.2)
                    : LuluColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selectedValue == options[i]
                      ? LuluColors.lavenderMist
                      : LuluColors.glassBorder,
                  width: selectedValue == options[i] ? 2 : 1,
                ),
              ),
              child: Text(
                displayLabels[i],
                style: LuluTextStyles.labelMedium.copyWith(
                  color: selectedValue == options[i]
                      ? LuluColors.lavenderMist
                      : LuluTextColors.secondary,
                  fontWeight: selectedValue == options[i]
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAmountInput({
    required String label,
    required double value,
    required String unit,
    required List<int> presets,
    double step = 10,
    double minValue = 0,
    double maxValue = 999,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
        const SizedBox(height: LuluSpacing.sm),

        // 프리셋 버튼
        if (presets.isNotEmpty) ...[
          Row(
            children: [
              for (int i = 0; i < presets.length; i++) ...[
                if (i > 0) const SizedBox(width: LuluSpacing.sm),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(presets[i].toDouble()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: value.toInt() == presets[i]
                            ? LuluColors.lavenderMist.withValues(alpha: 0.2)
                            : LuluColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: value.toInt() == presets[i]
                              ? LuluColors.lavenderMist
                              : LuluColors.glassBorder,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${presets[i]}$unit',
                          style: LuluTextStyles.labelSmall.copyWith(
                            color: value.toInt() == presets[i]
                                ? LuluColors.lavenderMist
                                : LuluTextColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: LuluSpacing.sm),
        ],

        // 조절 버튼 + 입력
        Row(
          children: [
            // -버튼
            GestureDetector(
              onTap: () {
                final newValue = (value - step).clamp(minValue, maxValue);
                onChanged(newValue);
              },
              child: Container(
                padding: const EdgeInsets.all(LuluSpacing.sm),
                decoration: BoxDecoration(
                  color: LuluColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: LuluColors.glassBorder),
                ),
                child: Icon(
                  Icons.remove,
                  color: LuluTextColors.secondary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: LuluSpacing.md),
            // 값 표시
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LuluSpacing.md,
                  vertical: LuluSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: LuluColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  step < 1
                      ? '${value.toStringAsFixed(1)}$unit'
                      : '${value.toInt()}$unit',
                  style: LuluTextStyles.bodyLarge.copyWith(
                    color: LuluTextColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: LuluSpacing.md),
            // +버튼
            GestureDetector(
              onTap: () {
                final newValue = (value + step).clamp(minValue, maxValue);
                onChanged(newValue);
              },
              child: Container(
                padding: const EdgeInsets.all(LuluSpacing.sm),
                decoration: BoxDecoration(
                  color: LuluColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: LuluColors.glassBorder),
                ),
                child: Icon(
                  Icons.add,
                  color: LuluTextColors.secondary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '메모',
          style: LuluTextStyles.labelLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),
        Container(
          padding: LuluSpacing.inputPadding,
          decoration: BoxDecoration(
            color: LuluColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.primary,
            ),
            decoration: InputDecoration(
              hintText: '메모를 입력하세요',
              hintStyle: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.tertiary,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: LuluSpacing.cardPadding,
      decoration: BoxDecoration(
        color: LuluStatusColors.errorSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: LuluStatusColors.error,
            size: 20,
          ),
          const SizedBox(width: LuluSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: LuluTextStyles.bodySmall.copyWith(
                color: LuluStatusColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: LuluColors.lavenderMist,
          foregroundColor: LuluColors.midnightNavy,
          disabledBackgroundColor: LuluColors.surfaceElevated,
          disabledForegroundColor: LuluTextColors.disabled,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: LuluColors.midnightNavy,
                ),
              )
            : Text(
                '저장하기',
                style: LuluTextStyles.labelLarge.copyWith(
                  color: LuluColors.midnightNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _selectTime({required bool isStart}) async {
    final currentTime = isStart ? _startTime : (_endTime ?? DateTime.now());

    final result = await showLuluDateTimePicker(
      context: context,
      initialDateTime: currentTime,
      minimumDate: DateTime.now().subtract(const Duration(days: 7)),
      maximumDate: DateTime.now(),
      title: isStart ? '시작 시간' : '종료 시간',
    );

    if (result != null) {
      setState(() {
        if (isStart) {
          _startTime = result;
        } else {
          _endTime = result;
        }
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final updatedActivity = widget.activity.copyWith(
        startTime: _startTime,
        endTime: _endTime,
        data: _data.isNotEmpty ? _data : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        updatedAt: DateTime.now(),
      );

      await _activityRepository.updateActivity(updatedActivity);

      if (mounted) {
        Navigator.of(context).pop(updatedActivity);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '저장 실패: $e';
        _isLoading = false;
      });
    }
  }

  String _getActivityEmoji(ActivityType type) {
    switch (type) {
      case ActivityType.feeding:
        return '🍼';
      case ActivityType.sleep:
        return '😴';
      case ActivityType.diaper:
        return '👶';
      case ActivityType.play:
        return '🎮';
      case ActivityType.health:
        return '🏥';
    }
  }

  String _getActivityTitle(ActivityType type) {
    switch (type) {
      case ActivityType.feeding:
        return '수유';
      case ActivityType.sleep:
        return '수면';
      case ActivityType.diaper:
        return '기저귀';
      case ActivityType.play:
        return '놀이';
      case ActivityType.health:
        return '건강';
    }
  }
}
