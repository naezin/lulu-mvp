import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_model.dart';
import '../../../data/models/baby_type.dart';
import '../../../shared/widgets/baby_tab_bar.dart';
import '../../../shared/widgets/quick_record_button.dart';
import '../providers/record_provider.dart';

/// 수면 기록 화면 (v5.0)
///
/// MVP-F: BabyTabBar + QuickRecordButton UX
/// - "둘 다" 버튼 제거됨
/// - 이전과 같이 버튼으로 원탭 저장 지원
class SleepRecordScreen extends StatefulWidget {
  final String familyId;
  final List<BabyModel> babies;
  final String? preselectedBabyId;
  final ActivityModel? lastSleepRecord;

  const SleepRecordScreen({
    super.key,
    required this.familyId,
    required this.babies,
    this.preselectedBabyId,
    this.lastSleepRecord,
  });

  @override
  State<SleepRecordScreen> createState() => _SleepRecordScreenState();
}

class _SleepRecordScreenState extends State<SleepRecordScreen> {
  final _notesController = TextEditingController();
  bool _isSleepNow = true; // 지금 재우기 vs 기록 추가
  bool _isQuickSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordProvider>().initialize(
            familyId: widget.familyId,
            babies: widget.babies,
            preselectedBabyId: widget.preselectedBabyId,
          );
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuluColors.midnightNavy,
      appBar: AppBar(
        backgroundColor: LuluColors.midnightNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: LuluTextColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '수면 기록',
          style: LuluTextStyles.titleMedium.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<RecordProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // 아기 탭바 (다태아 시 표시)
              if (widget.babies.length > 1)
                BabyTabBar(
                  babies: widget.babies,
                  selectedBabyId: provider.selectedBabyIds.isNotEmpty
                      ? provider.selectedBabyIds.first
                      : null,
                  onBabyChanged: (babyId) {
                    if (babyId != null) {
                      provider.setSelectedBabyIds([babyId]);
                    }
                  },
                ),

              Expanded(
                child: SingleChildScrollView(
                  padding: LuluSpacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 이전과 같이 빠른 기록 버튼
                      QuickRecordButton(
                        lastRecord: widget.lastSleepRecord,
                        activityType: ActivityType.sleep,
                        isLoading: _isQuickSaving,
                        onTap: () => _handleQuickSave(provider),
                      ),

                      if (widget.lastSleepRecord != null)
                        const SizedBox(height: LuluSpacing.xl),

                      // 기록 모드 선택 (지금 재우기 vs 기록 추가)
                      _buildModeSelector(),

                const SizedBox(height: LuluSpacing.xxl),

                // 수면 타입 선택 (밤잠/낮잠)
                _buildSleepTypeSelector(provider),

                const SizedBox(height: LuluSpacing.xxl),

                // 모드에 따른 UI
                if (_isSleepNow)
                  _buildSleepNowSection(provider)
                else
                  _buildAddRecordSection(provider),

                const SizedBox(height: LuluSpacing.xxl),

                // 메모
                _buildNotesInput(),

                const SizedBox(height: LuluSpacing.xxxl),

                // 저장 버튼
                _buildSaveButton(provider),

                // 에러 메시지
                if (provider.errorMessage != null) ...[
                  const SizedBox(height: LuluSpacing.md),
                  _buildErrorMessage(provider.errorMessage!),
                ],

                      const SizedBox(height: LuluSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleQuickSave(RecordProvider provider) async {
    if (_isQuickSaving || widget.lastSleepRecord == null) return;

    setState(() => _isQuickSaving = true);

    try {
      // 마지막 기록의 데이터를 복사
      final lastData = widget.lastSleepRecord!.data;
      if (lastData == null) return;

      final sleepType = lastData['sleep_type'] as String? ?? 'nap';
      provider.setSleepType(sleepType);

      // 지금 재우기 모드로 저장 (현재 시간)
      provider.setSleepStartTime(DateTime.now());
      provider.setSleepEndTime(null);

      final activity = await provider.saveSleep();
      if (activity != null && mounted) {
        Navigator.of(context).pop(activity);
      }
    } finally {
      if (mounted) {
        setState(() => _isQuickSaving = false);
      }
    }
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: _ModeButton(
            label: '지금 재우기',
            emoji: '🌙',
            isSelected: _isSleepNow,
            onTap: () => setState(() => _isSleepNow = true),
          ),
        ),
        const SizedBox(width: LuluSpacing.sm),
        Expanded(
          child: _ModeButton(
            label: '기록 추가',
            emoji: '📝',
            isSelected: !_isSleepNow,
            onTap: () => setState(() => _isSleepNow = false),
          ),
        ),
      ],
    );
  }

  Widget _buildSleepTypeSelector(RecordProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '수면 종류',
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),
        Row(
          children: [
            Expanded(
              child: _SleepTypeButton(
                label: '낮잠',
                emoji: '☀️',
                isSelected: provider.sleepType == 'nap',
                onTap: () => provider.setSleepType('nap'),
              ),
            ),
            const SizedBox(width: LuluSpacing.sm),
            Expanded(
              child: _SleepTypeButton(
                label: '밤잠',
                emoji: '🌙',
                isSelected: provider.sleepType == 'night',
                onTap: () => provider.setSleepType('night'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSleepNowSection(RecordProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 안내 카드
        Container(
          padding: LuluSpacing.cardPadding,
          decoration: BoxDecoration(
            color: LuluActivityColors.sleepBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: LuluActivityColors.sleep.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: LuluActivityColors.sleep.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('😴', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: LuluSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '지금 수면 시작',
                      style: LuluTextStyles.titleSmall.copyWith(
                        color: LuluTextColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '저장하면 수면이 시작됩니다.\n나중에 깨면 종료 시간을 기록하세요.',
                      style: LuluTextStyles.caption.copyWith(
                        color: LuluTextColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: LuluSpacing.lg),

        // 시작 시간
        _buildTimeSection(
          label: '수면 시작',
          time: provider.sleepStartTime,
          onTimeChanged: provider.setSleepStartTime,
        ),
      ],
    );
  }

  Widget _buildAddRecordSection(RecordProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 시작 시간
        _buildTimeSection(
          label: '수면 시작',
          time: provider.sleepStartTime,
          onTimeChanged: provider.setSleepStartTime,
        ),

        const SizedBox(height: LuluSpacing.xxl),

        // 종료 시간
        _buildTimeSection(
          label: '수면 종료',
          time: provider.sleepEndTime ?? DateTime.now(),
          onTimeChanged: provider.setSleepEndTime,
        ),

        // 수면 시간 표시
        if (provider.sleepEndTime != null) ...[
          const SizedBox(height: LuluSpacing.lg),
          _buildDurationDisplay(provider),
        ],
      ],
    );
  }

  Widget _buildTimeSection({
    required String label,
    required DateTime time,
    required ValueChanged<DateTime> onTimeChanged,
  }) {
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
            Expanded(
              child: _TimeButton(
                icon: Icons.calendar_today_rounded,
                text: DateFormat('M월 d일 (E)', 'ko').format(time),
                onTap: () => _selectDate(time, onTimeChanged),
              ),
            ),
            const SizedBox(width: LuluSpacing.sm),
            // 시간 선택
            Expanded(
              child: _TimeButton(
                icon: Icons.access_time_rounded,
                text: DateFormat('a h:mm', 'ko').format(time),
                onTap: () => _selectTime(time, onTimeChanged),
              ),
            ),
          ],
        ),
        const SizedBox(height: LuluSpacing.md),
        // 빠른 선택
        _QuickTimeButtons(
          currentTime: time,
          onTimeChanged: onTimeChanged,
        ),
      ],
    );
  }

  Widget _buildDurationDisplay(RecordProvider provider) {
    final duration = provider.sleepDurationMinutes;
    final hours = duration ~/ 60;
    final minutes = duration % 60;

    String durationText;
    if (hours == 0) {
      durationText = '$minutes분';
    } else if (minutes == 0) {
      durationText = '$hours시간';
    } else {
      durationText = '$hours시간 $minutes분';
    }

    return Container(
      padding: LuluSpacing.cardPadding,
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.timer_outlined,
            color: LuluActivityColors.sleep,
            size: 20,
          ),
          const SizedBox(width: LuluSpacing.sm),
          Text(
            '총 수면 시간: ',
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.secondary,
            ),
          ),
          Text(
            durationText,
            style: LuluTextStyles.titleSmall.copyWith(
              color: LuluActivityColors.sleep,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '메모 (선택)',
          style: LuluTextStyles.bodyLarge.copyWith(
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
              hintText: '수면 상태, 특이사항 등',
              hintStyle: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.tertiary,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              context.read<RecordProvider>().setNotes(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(RecordProvider provider) {
    final isValid = provider.isSelectionValid;
    final buttonText = _isSleepNow ? '수면 시작' : '저장하기';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isValid && !provider.isLoading
            ? () => _handleSave(provider)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: LuluActivityColors.sleep,
          foregroundColor: Colors.white,
          disabledBackgroundColor: LuluColors.surfaceElevated,
          disabledForegroundColor: LuluTextColors.disabled,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: provider.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSleepNow) ...[
                    const Text('🌙', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    buttonText,
                    style: LuluTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
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

  Future<void> _selectDate(DateTime current, ValueChanged<DateTime> onChanged) async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: LuluActivityColors.sleep,
              surface: LuluColors.deepBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      onChanged(DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        current.hour,
        current.minute,
      ));
    }
  }

  Future<void> _selectTime(DateTime current, ValueChanged<DateTime> onChanged) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: LuluActivityColors.sleep,
              surface: LuluColors.deepBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      onChanged(DateTime(
        current.year,
        current.month,
        current.day,
        selectedTime.hour,
        selectedTime.minute,
      ));
    }
  }

  Future<void> _handleSave(RecordProvider provider) async {
    // "지금 재우기" 모드면 종료 시간 없이 저장
    if (_isSleepNow) {
      provider.setSleepEndTime(null);
    }

    final activity = await provider.saveSleep();
    if (activity != null && mounted) {
      Navigator.of(context).pop(activity);
    }
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluActivityColors.sleepBg
              : LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? LuluActivityColors.sleep
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: LuluTextStyles.labelMedium.copyWith(
                color: isSelected
                    ? LuluActivityColors.sleep
                    : LuluTextColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
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
              color: LuluActivityColors.sleep,
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
              ? LuluActivityColors.sleepBg
              : LuluColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? LuluActivityColors.sleep : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: LuluTextStyles.caption.copyWith(
            color: isSelected ? LuluActivityColors.sleep : LuluTextColors.secondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SleepTypeButton extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _SleepTypeButton({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluActivityColors.sleepBg
              : LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? LuluActivityColors.sleep
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: LuluTextStyles.labelMedium.copyWith(
                color: isSelected
                    ? LuluActivityColors.sleep
                    : LuluTextColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
