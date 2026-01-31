import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_model.dart';
import '../../../data/models/baby_type.dart';
import '../../../shared/widgets/baby_tab_bar.dart';
import '../../../shared/widgets/quick_record_button.dart';
import '../providers/record_provider.dart';
import '../widgets/record_time_picker.dart';
import '../widgets/feeding_type_selector.dart';
import '../widgets/amount_input.dart';

/// 수유 기록 화면 (v5.0)
///
/// MVP-F: BabyTabBar + QuickRecordButton UX
/// - "둘 다" 버튼 제거됨
/// - 이전과 같이 버튼으로 원탭 저장 지원
class FeedingRecordScreen extends StatefulWidget {
  final String familyId;
  final List<BabyModel> babies;
  final String? preselectedBabyId;
  final ActivityModel? lastFeedingRecord;

  const FeedingRecordScreen({
    super.key,
    required this.familyId,
    required this.babies,
    this.preselectedBabyId,
    this.lastFeedingRecord,
  });

  @override
  State<FeedingRecordScreen> createState() => _FeedingRecordScreenState();
}

class _FeedingRecordScreenState extends State<FeedingRecordScreen> {
  final _notesController = TextEditingController();
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
          '수유 기록',
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
                      // 마지막 기록 반복 버튼 (MB-03)
                      QuickRecordButton(
                        lastRecord: widget.lastFeedingRecord,
                        activityType: ActivityType.feeding,
                        isLoading: _isQuickSaving,
                        onTap: () => _handleQuickSave(provider),
                        babyName: _getSelectedBabyName(provider),
                      ),

                      if (widget.lastFeedingRecord != null)
                        const SizedBox(height: LuluSpacing.xl),

                      // 수유 종류 선택
                      FeedingTypeSelector(
                        selectedType: provider.feedingType,
                        onTypeChanged: provider.setFeedingType,
                      ),

                      const SizedBox(height: LuluSpacing.xxl),

                      // 시간 선택
                      RecordTimePicker(
                        label: '수유 시간',
                        time: provider.recordTime,
                        onTimeChanged: provider.setRecordTime,
                      ),

                      const SizedBox(height: LuluSpacing.xxl),

                      // 모유 수유 시 좌/우 선택
                      if (provider.feedingType == 'breast') ...[
                        _buildBreastSideSelector(provider),
                        const SizedBox(height: LuluSpacing.xxl),
                      ],

                      // 수유량 또는 수유 시간 (종류에 따라)
                      if (provider.feedingType == 'breast')
                        _buildDurationInput(provider)
                      else
                        _buildAmountInput(provider),

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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
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
    if (_isQuickSaving || widget.lastFeedingRecord == null) return;

    setState(() => _isQuickSaving = true);

    try {
      // 마지막 기록의 데이터를 복사하여 새 기록 생성
      final lastData = widget.lastFeedingRecord!.data;
      if (lastData == null) return;

      // RecordProvider 상태를 마지막 기록으로 설정
      final feedingType = lastData['feeding_type'] as String? ?? 'bottle';
      provider.setFeedingType(feedingType);

      if (feedingType == 'breast') {
        final breastSide = lastData['breast_side'] as String?;
        if (breastSide != null) provider.setBreastSide(breastSide);
        final duration = lastData['duration_minutes'] as int?;
        if (duration != null) provider.setFeedingDuration(duration);
      } else {
        final amount = lastData['amount_ml'] as num?;
        if (amount != null) provider.setFeedingAmount(amount.toDouble());
      }

      // 현재 시간으로 저장
      provider.setRecordTime(DateTime.now());

      final activity = await provider.saveFeeding();
      if (activity != null && mounted) {
        Navigator.of(context).pop(activity);
      }
    } finally {
      if (mounted) {
        setState(() => _isQuickSaving = false);
      }
    }
  }

  Widget _buildBreastSideSelector(RecordProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '수유 위치',
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),
        Row(
          children: [
            Expanded(
              child: _BreastSideButton(
                label: '왼쪽',
                icon: LuluIcons.breastfeeding,
                isSelected: provider.breastSide == 'left',
                onTap: () => provider.setBreastSide('left'),
              ),
            ),
            const SizedBox(width: LuluSpacing.sm),
            Expanded(
              child: _BreastSideButton(
                label: '오른쪽',
                icon: LuluIcons.breastfeeding,
                isSelected: provider.breastSide == 'right',
                onTap: () => provider.setBreastSide('right'),
                isFlipped: true,
              ),
            ),
            const SizedBox(width: LuluSpacing.sm),
            Expanded(
              child: _BreastSideButton(
                label: '양쪽',
                icon: LuluIcons.baby,
                isSelected: provider.breastSide == 'both',
                onTap: () => provider.setBreastSide('both'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationInput(RecordProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '수유 시간',
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),
        Row(
          children: [
            Expanded(
              child: _DurationButton(
                label: '5분',
                isSelected: provider.feedingDuration == 5,
                onTap: () => provider.setFeedingDuration(5),
              ),
            ),
            const SizedBox(width: LuluSpacing.sm),
            Expanded(
              child: _DurationButton(
                label: '10분',
                isSelected: provider.feedingDuration == 10,
                onTap: () => provider.setFeedingDuration(10),
              ),
            ),
            const SizedBox(width: LuluSpacing.sm),
            Expanded(
              child: _DurationButton(
                label: '15분',
                isSelected: provider.feedingDuration == 15,
                onTap: () => provider.setFeedingDuration(15),
              ),
            ),
            const SizedBox(width: LuluSpacing.sm),
            Expanded(
              child: _DurationButton(
                label: '20분',
                isSelected: provider.feedingDuration == 20,
                onTap: () => provider.setFeedingDuration(20),
              ),
            ),
          ],
        ),
        const SizedBox(height: LuluSpacing.md),
        // 직접 입력
        Container(
          padding: LuluSpacing.inputPadding,
          decoration: BoxDecoration(
            color: LuluColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  style: LuluTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: '직접 입력',
                    hintStyle: LuluTextStyles.bodyMedium.copyWith(
                      color: LuluTextColors.tertiary,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    final minutes = int.tryParse(value) ?? 0;
                    provider.setFeedingDuration(minutes);
                  },
                ),
              ),
              Text(
                '분',
                style: LuluTextStyles.bodyMedium.copyWith(
                  color: LuluTextColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInput(RecordProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '수유량',
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),
        AmountInput(
          amount: provider.feedingAmount,
          onAmountChanged: provider.setFeedingAmount,
          unit: 'ml',
          presets: const [60, 90, 120, 150],
        ),
      ],
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
              hintText: '특이사항을 기록하세요',
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

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isValid && !provider.isLoading
            ? () => _handleSave(provider)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: LuluActivityColors.feeding,
          foregroundColor: LuluColors.midnightNavy,
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
                  color: LuluColors.midnightNavy,
                ),
              )
            : Text(
                '저장하기',
                style: LuluTextStyles.labelLarge.copyWith(
                  color: LuluColors.midnightNavy,
                ),
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

  Future<void> _handleSave(RecordProvider provider) async {
    final activity = await provider.saveFeeding();
    if (activity != null && mounted) {
      Navigator.of(context).pop(activity);
    }
  }
}

class _DurationButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluActivityColors.feedingBg
              : LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? LuluActivityColors.feeding
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: LuluTextStyles.labelMedium.copyWith(
              color: isSelected
                  ? LuluActivityColors.feeding
                  : LuluTextColors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _BreastSideButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFlipped;

  const _BreastSideButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isFlipped = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluActivityColors.feedingBg
              : LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? LuluActivityColors.feeding
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.flip(
              flipX: isFlipped,
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? LuluActivityColors.feeding
                    : LuluTextColors.secondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: LuluTextStyles.labelMedium.copyWith(
                color: isSelected
                    ? LuluActivityColors.feeding
                    : LuluTextColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
