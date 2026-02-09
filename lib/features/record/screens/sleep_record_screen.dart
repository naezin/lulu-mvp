import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_shadows.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_model.dart';
import '../../../data/models/baby_type.dart';
import '../../../shared/widgets/baby_tab_bar.dart';
import '../../../shared/widgets/datetime_picker/datetime_picker_sheet.dart';
import '../../../shared/widgets/quick_record_button.dart';
import '../providers/record_provider.dart';
import '../providers/ongoing_sleep_provider.dart';

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
          icon: const Icon(LuluIcons.close, color: LuluTextColors.primary),
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
      body: Consumer2<RecordProvider, OngoingSleepProvider>(
        builder: (context, provider, ongoingSleepProvider, _) {
          // 현재 선택된 아기의 진행 중 수면 확인
          final hasOngoingSleep = ongoingSleepProvider.hasSleepInProgress &&
              ongoingSleepProvider.currentBabyId == provider.selectedBabyId;

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
                      // QA-03: 진행 중인 수면 종료 섹션
                      if (hasOngoingSleep) ...[
                        _buildOngoingSleepSection(ongoingSleepProvider),
                        const SizedBox(height: LuluSpacing.xl),
                        const Divider(color: LuluColors.surfaceElevated),
                        const SizedBox(height: LuluSpacing.lg),
                        Text(
                          '또는 새 기록 추가',
                          style: LuluTextStyles.bodySmall.copyWith(
                            color: LuluTextColors.tertiary,
                          ),
                        ),
                        const SizedBox(height: LuluSpacing.md),
                      ],

                      // 마지막 기록 반복 버튼 (진행 중 수면 없을 때만, MB-03)
                      if (!hasOngoingSleep) ...[
                        QuickRecordButton(
                          lastRecord: widget.lastSleepRecord,
                          activityType: ActivityType.sleep,
                          isLoading: _isQuickSaving,
                          onTap: () => _handleQuickSave(provider),
                          babyName: _getSelectedBabyName(provider),
                        ),
                        if (widget.lastSleepRecord != null)
                          const SizedBox(height: LuluSpacing.xl),
                      ],

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

              // MO-01: 저장 버튼 하단 고정
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(LuluSpacing.lg),
                  decoration: BoxDecoration(
                    color: LuluColors.midnightNavy,
                    boxShadow: LuluShadows.topBar,
                  ),
                  child: _buildSaveButton(provider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// MB-03: 현재 선택된 아기 이름 반환
  String? _getSelectedBabyName(RecordProvider provider) {
    if (provider.selectedBabyIds.isEmpty) return null;
    final selectedId = provider.selectedBabyIds.first;
    final baby = widget.babies.where((b) => b.id == selectedId).firstOrNull;
    return baby?.name;
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

  /// QA-03: 진행 중인 수면 종료 섹션
  Widget _buildOngoingSleepSection(OngoingSleepProvider provider) {
    final babyName = provider.ongoingSleep?.babyName ?? '아기';
    final sleepType = provider.ongoingSleep?.sleepType == 'night' ? '밤잠' : '낮잠';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LuluActivityColors.sleepLight,
            LuluActivityColors.sleepSubtle,
          ],
        ),
        borderRadius: BorderRadius.circular(LuluRadius.lg),
        border: Border.all(
          color: LuluActivityColors.sleepMedium,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // 헤더
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: LuluActivityColors.sleepSelected,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(LuluIcons.sleep, size: 24, color: LuluActivityColors.sleep),
                ),
              ),
              const SizedBox(width: LuluSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$babyName $sleepType 중',
                      style: LuluTextStyles.titleSmall.copyWith(
                        color: LuluTextColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.formattedElapsedTime,
                      style: LuluTextStyles.displaySmall.copyWith(
                        color: LuluActivityColors.sleep,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: LuluSpacing.lg),

          // 버튼들
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _endSleep(provider),
                  icon: const Icon(LuluIcons.sleep),
                  label: const Text('수면 종료'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LuluActivityColors.sleep,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(LuluRadius.sm),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: LuluSpacing.md),
              TextButton.icon(
                onPressed: () => _cancelSleep(provider),
                icon: const Icon(LuluIcons.close, size: 18),
                label: const Text('취소'),
                style: TextButton.styleFrom(
                  foregroundColor: LuluTextColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _endSleep(OngoingSleepProvider provider) async {
    final activity = await provider.endSleep();
    if (activity != null && mounted) {
      // 🔧 Sprint 19 G-R7: 토스트 제거 → 햅틱 대체
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(activity);
    }
  }

  Future<void> _cancelSleep(OngoingSleepProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LuluColors.surfaceCard,
        title: Text(
          '수면을 취소할까요?',
          style: LuluTextStyles.titleMedium.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        content: Text(
          '진행 중인 수면 기록이 삭제됩니다.',
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니오'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: LuluStatusColors.error,
            ),
            child: const Text('취소'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.cancelSleep();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: _ModeButton(
            label: '지금 재우기',
            icon: LuluIcons.moon,
            isSelected: _isSleepNow,
            onTap: () => setState(() => _isSleepNow = true),
          ),
        ),
        const SizedBox(width: LuluSpacing.sm),
        Expanded(
          child: _ModeButton(
            label: '기록 추가',
            icon: LuluIcons.note,
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
                icon: LuluIcons.sun,
                isSelected: provider.sleepType == 'nap',
                onTap: () => provider.setSleepType('nap'),
              ),
            ),
            const SizedBox(width: LuluSpacing.sm),
            Expanded(
              child: _SleepTypeButton(
                label: '밤잠',
                icon: LuluIcons.moon,
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
            borderRadius: BorderRadius.circular(LuluRadius.md),
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
                  color: LuluActivityColors.sleepSelected,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(LuluIcons.sleep, size: 24, color: LuluActivityColors.sleep),
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
                      '저장하면 수면이 시작됩니다.\n아기가 깨면 홈 화면에서 종료 버튼을 눌러주세요.',
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

  /// HOTFIX v1.1: 통합 DateTime Picker 사용
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
        // 통합 날짜/시간 버튼 (원탭 → 피커 열기)
        _IntegratedTimeButton(
          time: time,
          onTap: () => _selectDateTime(time, onTimeChanged, label),
        ),
      ],
    );
  }

  /// HOTFIX v1.1: 통합 DateTime 선택 (바텀시트)
  Future<void> _selectDateTime(
    DateTime current,
    ValueChanged<DateTime> onChanged,
    String title,
  ) async {
    final now = DateTime.now();
    final result = await showLuluDateTimePicker(
      context: context,
      initialDateTime: current,
      minimumDate: now.subtract(const Duration(days: 7)),
      maximumDate: now,
      title: title,
    );

    if (result != null) {
      onChanged(result);
    }
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
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LuluIcons.timerOutlined,
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
            borderRadius: BorderRadius.circular(LuluRadius.sm),
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
            borderRadius: BorderRadius.circular(LuluRadius.md),
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
                    const Icon(LuluIcons.moon, size: 18, color: Colors.white),
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
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
      child: Row(
        children: [
          Icon(
            LuluIcons.errorOutline,
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

  Future<void> _handleSave(RecordProvider provider) async {
    // "지금 재우기" 모드면 OngoingSleepProvider 사용
    if (_isSleepNow) {
      final ongoingSleepProvider = context.read<OngoingSleepProvider>();
      final selectedBabyId = provider.selectedBabyId;
      final selectedBaby = widget.babies.firstWhere(
        (b) => b.id == selectedBabyId,
        orElse: () => widget.babies.first,
      );

      await ongoingSleepProvider.startSleep(
        babyId: selectedBaby.id,
        familyId: widget.familyId,
        sleepType: provider.sleepType,
        babyName: selectedBaby.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(LuluIcons.sleep, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '${selectedBaby.name} 수면 시작! 홈에서 종료할 수 있어요',
                  style: LuluTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: LuluActivityColors.sleep,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LuluRadius.sm),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
    } else {
      // "기록 추가" 모드: 시작/종료 시간 함께 저장
      final activity = await provider.saveSleep();
      if (activity != null && mounted) {
        Navigator.of(context).pop(activity);
      }
    }
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
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
          borderRadius: BorderRadius.circular(LuluRadius.sm),
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
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? LuluActivityColors.sleep
                  : LuluTextColors.secondary,
            ),
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

/// HOTFIX v1.1: 통합 날짜/시간 버튼
class _IntegratedTimeButton extends StatelessWidget {
  final DateTime time;
  final VoidCallback onTap;

  const _IntegratedTimeButton({
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '시간 선택',
      child: Material(
        color: LuluColors.surfaceElevated,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LuluSpacing.lg,
              vertical: LuluSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LuluIcons.time,
                  size: 20,
                  color: LuluActivityColors.sleep,
                ),
                const SizedBox(width: LuluSpacing.sm),
                Text(
                  DateFormat('M월 d일 (E) a h:mm', 'ko').format(time),
                  style: LuluTextStyles.bodyMedium.copyWith(
                    color: LuluTextColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: LuluSpacing.sm),
                Icon(
                  LuluIcons.chevronDown,
                  size: 20,
                  color: LuluTextColors.tertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SleepTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SleepTypeButton({
    required this.label,
    required this.icon,
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
          borderRadius: BorderRadius.circular(LuluRadius.sm),
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
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? LuluActivityColors.sleep
                  : LuluTextColors.secondary,
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
