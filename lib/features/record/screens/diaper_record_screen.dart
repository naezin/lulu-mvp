import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_shadows.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_model.dart';
import '../../../data/models/baby_type.dart';
import '../../../shared/widgets/baby_tab_bar.dart';
import '../../../shared/widgets/quick_record_button.dart';
import '../providers/record_provider.dart';
import '../widgets/record_time_picker.dart';

/// 기저귀 기록 화면 (v5.0)
///
/// MVP-F: BabyTabBar + QuickRecordButton UX
/// - "둘 다" 버튼 제거됨
/// - 이전과 같이 버튼으로 원탭 저장 지원
class DiaperRecordScreen extends StatefulWidget {
  final String familyId;
  final List<BabyModel> babies;
  final String? preselectedBabyId;
  final ActivityModel? lastDiaperRecord;

  const DiaperRecordScreen({
    super.key,
    required this.familyId,
    required this.babies,
    this.preselectedBabyId,
    this.lastDiaperRecord,
  });

  @override
  State<DiaperRecordScreen> createState() => _DiaperRecordScreenState();
}

class _DiaperRecordScreenState extends State<DiaperRecordScreen> {
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
          icon: const Icon(LuluIcons.close, color: LuluTextColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          S.of(context)?.recordTitleDiaper ?? 'Diaper Record',
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
                        lastRecord: widget.lastDiaperRecord,
                        activityType: ActivityType.diaper,
                        isLoading: _isQuickSaving,
                        onTap: () => _handleQuickSave(provider),
                        babyName: _getSelectedBabyName(provider),
                      ),

                      if (widget.lastDiaperRecord != null)
                        const SizedBox(height: LuluSpacing.xl),

                      // 기저귀 종류 선택
                      _buildDiaperTypeSelector(provider),

                      // 대변 색상 선택 (대변/혼합 선택 시에만 표시)
                      if (provider.diaperType == 'dirty' ||
                          provider.diaperType == 'both') ...[
                        const SizedBox(height: LuluSpacing.xxl),
                        _buildStoolColorSelector(provider),
                      ],

                      const SizedBox(height: LuluSpacing.xxl),

                      // 시간 선택
                      RecordTimePicker(
                        label: S.of(context)?.diaperChangeTime ?? 'Diaper Change Time',
                        time: provider.recordTime,
                        onTimeChanged: provider.setRecordTime,
                      ),

                      const SizedBox(height: LuluSpacing.xxl),

                      // 메모
                      _buildNotesInput(),

                      // 에러 메시지
                      if (provider.errorMessage != null) ...[
                        const SizedBox(height: LuluSpacing.md),
                        _buildErrorMessage(_localizeError(provider.errorMessage!)),
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
    if (_isQuickSaving || widget.lastDiaperRecord == null) return;

    setState(() => _isQuickSaving = true);

    try {
      final lastData = widget.lastDiaperRecord!.data;
      if (lastData == null) return;

      final diaperType = lastData['diaper_type'] as String? ?? 'wet';
      provider.setDiaperType(diaperType);

      final stoolColor = lastData['stool_color'] as String?;
      if (stoolColor != null) {
        provider.setStoolColor(stoolColor);
      }

      provider.setRecordTime(DateTime.now());

      final activity = await provider.saveDiaper();
      if (activity != null && mounted) {
        Navigator.of(context).pop(activity);
      }
    } finally {
      if (mounted) {
        setState(() => _isQuickSaving = false);
      }
    }
  }

  Widget _buildDiaperTypeSelector(RecordProvider provider) {
    final l10n = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.diaperStatus ?? 'Diaper Status',
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),
        Row(
          children: [
            Expanded(
              child: _DiaperTypeButton(
                type: 'wet',
                label: l10n?.diaperTypeWet ?? 'Wet',
                icon: LuluIcons.diaperWet,
                isSelected: provider.diaperType == 'wet',
                onTap: () => provider.setDiaperType('wet'),
              ),
            ),
            const SizedBox(width: LuluSpacing.sm),
            Expanded(
              child: _DiaperTypeButton(
                type: 'dirty',
                label: l10n?.diaperTypeDirty ?? 'Dirty',
                iconWidget: LuluIcons.poopIcon(
                  size: 32,
                  color: provider.diaperType == 'dirty'
                      ? LuluActivityColors.diaper
                      : LuluTextColors.secondary,
                ),
                isSelected: provider.diaperType == 'dirty',
                onTap: () => provider.setDiaperType('dirty'),
              ),
            ),
          ],
        ),
        const SizedBox(height: LuluSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _DiaperTypeButton(
                type: 'both',
                label: l10n?.diaperTypeBoth ?? 'Both',
                icon: LuluIcons.diaperBoth,
                isSelected: provider.diaperType == 'both',
                onTap: () => provider.setDiaperType('both'),
              ),
            ),
            const SizedBox(width: LuluSpacing.sm),
            Expanded(
              child: _DiaperTypeButton(
                type: 'dry',
                label: l10n?.diaperTypeDry ?? 'Dry',
                icon: LuluIcons.diaperDry,
                isSelected: provider.diaperType == 'dry',
                onTap: () => provider.setDiaperType('dry'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStoolColorSelector(RecordProvider provider) {
    final l10n = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.stoolColorOptional ?? 'Stool Color (optional)',
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.sm),
        Text(
          l10n?.stoolColorHelpText ?? 'Selecting a color helps with health tracking',
          style: LuluTextStyles.bodySmall.copyWith(
            color: LuluTextColors.tertiary,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),
        Wrap(
          spacing: LuluSpacing.sm,
          runSpacing: LuluSpacing.sm,
          children: [
            _StoolColorButton(
              color: 'yellow',
              label: l10n?.stoolColorYellow ?? 'Yellow',
              colorValue: const Color(0xFFF9A825),
              isSelected: provider.stoolColor == 'yellow',
              onTap: () => provider.setStoolColor(
                provider.stoolColor == 'yellow' ? null : 'yellow',
              ),
            ),
            _StoolColorButton(
              color: 'brown',
              label: l10n?.stoolColorBrown ?? 'Brown',
              colorValue: const Color(0xFF6D4C41),
              isSelected: provider.stoolColor == 'brown',
              onTap: () => provider.setStoolColor(
                provider.stoolColor == 'brown' ? null : 'brown',
              ),
            ),
            _StoolColorButton(
              color: 'green',
              label: l10n?.stoolColorGreen ?? 'Green',
              colorValue: const Color(0xFF4CAF50),
              isSelected: provider.stoolColor == 'green',
              onTap: () => provider.setStoolColor(
                provider.stoolColor == 'green' ? null : 'green',
              ),
            ),
            _StoolColorButton(
              color: 'black',
              label: l10n?.stoolColorBlack ?? 'Black',
              colorValue: const Color(0xFF212121),
              isSelected: provider.stoolColor == 'black',
              isWarning: true,
              onTap: () => provider.setStoolColor(
                provider.stoolColor == 'black' ? null : 'black',
              ),
            ),
            _StoolColorButton(
              color: 'red',
              label: l10n?.stoolColorRed ?? 'Red',
              colorValue: const Color(0xFFE53935),
              isSelected: provider.stoolColor == 'red',
              isWarning: true,
              onTap: () => provider.setStoolColor(
                provider.stoolColor == 'red' ? null : 'red',
              ),
            ),
            _StoolColorButton(
              color: 'white',
              label: l10n?.stoolColorWhite ?? 'White',
              colorValue: const Color(0xFFECEFF1),
              isSelected: provider.stoolColor == 'white',
              isWarning: true,
              onTap: () => provider.setStoolColor(
                provider.stoolColor == 'white' ? null : 'white',
              ),
            ),
          ],
        ),
        // 경고 메시지 (검정/빨강/흰색 선택 시)
        if (provider.stoolColor == 'black' ||
            provider.stoolColor == 'red' ||
            provider.stoolColor == 'white') ...[
          const SizedBox(height: LuluSpacing.md),
          Container(
            padding: LuluSpacing.cardPadding,
            decoration: BoxDecoration(
              color: LuluStatusColors.warningSoft,
              borderRadius: BorderRadius.circular(LuluRadius.sm),
            ),
            child: Row(
              children: [
                Icon(
                  LuluIcons.statusWarn,
                  color: LuluStatusColors.warning,
                  size: 20,
                ),
                const SizedBox(width: LuluSpacing.sm),
                Expanded(
                  child: Text(
                    l10n?.stoolColorWarning ?? 'This color may require medical consultation.\nIf it persists, we recommend visiting a pediatrician.',
                    style: LuluTextStyles.bodySmall.copyWith(
                      color: LuluStatusColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotesInput() {
    final l10n = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.notesOptionalLabel ?? 'Notes (optional)',
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
              hintText: l10n?.diaperNotesHint ?? 'Color, amount, unusual notes, etc.',
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
          backgroundColor: LuluActivityColors.diaper,
          foregroundColor: LuluColors.midnightNavy,
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
                  color: LuluColors.midnightNavy,
                ),
              )
            : Text(
                S.of(context)?.buttonSave ?? 'Save',
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

  String _localizeError(String errorKey) {
    final l10n = S.of(context);
    if (errorKey == 'errorSelectBaby') {
      return l10n?.errorSelectBaby ?? 'Please select a baby';
    } else if (errorKey == 'errorNoFamily') {
      return l10n?.errorNoFamily ?? 'No family information';
    } else if (errorKey.startsWith('errorSaveFailed:')) {
      final detail = errorKey.substring('errorSaveFailed:'.length);
      return l10n?.errorSaveFailed(detail) ?? 'Save failed: $detail';
    }
    return errorKey;
  }

  Future<void> _handleSave(RecordProvider provider) async {
    final activity = await provider.saveDiaper();
    if (activity != null && mounted) {
      Navigator.of(context).pop(activity);
    }
  }
}

class _DiaperTypeButton extends StatelessWidget {
  final String type;
  final String label;
  final IconData? icon;
  final Widget? iconWidget;
  final bool isSelected;
  final VoidCallback onTap;

  const _DiaperTypeButton({
    required this.type,
    required this.label,
    this.icon,
    this.iconWidget,
    required this.isSelected,
    required this.onTap,
  }) : assert(icon != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: LuluSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluActivityColors.diaperBg
              : LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(LuluRadius.md),
          border: Border.all(
            color: isSelected
                ? LuluActivityColors.diaper
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            if (iconWidget != null)
              SizedBox(width: 32, height: 32, child: iconWidget!)
            else
              Icon(
                icon,
                size: 32,
                color: isSelected
                    ? LuluActivityColors.diaper
                    : LuluTextColors.secondary,
              ),
            const SizedBox(height: LuluSpacing.sm),
            Text(
              label,
              style: LuluTextStyles.labelMedium.copyWith(
                color: isSelected
                    ? LuluActivityColors.diaper
                    : LuluTextColors.secondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 대변 색상 선택 버튼
class _StoolColorButton extends StatelessWidget {
  final String color;
  final String label;
  final Color colorValue;
  final bool isSelected;
  final bool isWarning;
  final VoidCallback onTap;

  const _StoolColorButton({
    required this.color,
    required this.label,
    required this.colorValue,
    required this.isSelected,
    this.isWarning = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        padding: const EdgeInsets.symmetric(
          vertical: LuluSpacing.md,
          horizontal: LuluSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorValue.withValues(alpha: 0.2)
              : LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          border: Border.all(
            color: isSelected ? colorValue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colorValue,
                shape: BoxShape.circle,
                border: color == 'white'
                    ? Border.all(color: LuluTextColors.tertiary, width: 1)
                    : null,
              ),
            ),
            const SizedBox(height: LuluSpacing.xs),
            Text(
              label,
              style: LuluTextStyles.labelSmall.copyWith(
                color: isSelected ? colorValue : LuluTextColors.secondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            // 높이 통일: 모든 버튼에 아이콘 공간 확보 (isWarning 아닐 때는 투명)
            const SizedBox(height: 2),
            Icon(
              LuluIcons.statusWarn,
              size: 12,
              color: isWarning
                  ? (isSelected ? LuluStatusColors.warning : LuluTextColors.tertiary)
                  : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
