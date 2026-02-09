import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/generated/app_localizations.dart' show S;

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
import '../../../shared/widgets/quick_record_button.dart';
import '../providers/record_provider.dart';
import '../widgets/record_time_picker.dart';
import '../widgets/temperature_slider.dart';

/// 건강 기록 화면 (v5.0)
///
/// MVP-F: BabyTabBar + QuickRecordButton UX
/// - "둘 다" 버튼 제거됨
/// - 이전과 같이 버튼으로 원탭 저장 지원
class HealthRecordScreen extends StatefulWidget {
  final String familyId;
  final List<BabyModel> babies;
  final String? preselectedBabyId;
  final ActivityModel? lastHealthRecord;

  const HealthRecordScreen({
    super.key,
    required this.familyId,
    required this.babies,
    this.preselectedBabyId,
    this.lastHealthRecord,
  });

  @override
  State<HealthRecordScreen> createState() => _HealthRecordScreenState();
}

class _HealthRecordScreenState extends State<HealthRecordScreen> {
  final _notesController = TextEditingController();
  final _medicationController = TextEditingController();
  final _hospitalController = TextEditingController();
  bool _isQuickSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RecordProvider>();
      provider.initialize(
        familyId: widget.familyId,
        babies: widget.babies,
        preselectedBabyId: widget.preselectedBabyId,
      );
      // UX-03: 기본 체온 36.5도 설정
      provider.setTemperature(36.5);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _medicationController.dispose();
    _hospitalController.dispose();
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
          S.of(context)!.recordTitleHealth,
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
                        lastRecord: widget.lastHealthRecord,
                        activityType: ActivityType.health,
                        isLoading: _isQuickSaving,
                        onTap: () => _handleQuickSave(provider),
                        babyName: _getSelectedBabyName(provider),
                      ),

                      if (widget.lastHealthRecord != null)
                        const SizedBox(height: LuluSpacing.xl),

                      // 기록 유형 선택
                      _buildHealthTypeSelector(provider),

                      const SizedBox(height: LuluSpacing.xxl),

                      // 유형별 상세 입력
                      _buildHealthTypeContent(provider),

                      const SizedBox(height: LuluSpacing.xxl),

                      // 시간 선택
                      RecordTimePicker(
                        label: S.of(context)!.labelRecordTime,
                        time: provider.recordTime,
                        onTimeChanged: provider.setRecordTime,
                      ),

                      const SizedBox(height: LuluSpacing.xxl),

                      // 메모
                      _buildNotesInput(),

                      const SizedBox(height: LuluSpacing.lg),

                      // 의료 면책 문구
                      _buildMedicalDisclaimer(),

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
    if (_isQuickSaving || widget.lastHealthRecord == null) return;

    setState(() => _isQuickSaving = true);

    try {
      final lastData = widget.lastHealthRecord!.data;
      if (lastData == null) return;

      final healthType = lastData['health_type'] as String? ?? 'temperature';
      provider.setHealthType(healthType);

      if (healthType == 'temperature') {
        final temp = lastData['temperature'] as num?;
        if (temp != null) provider.setTemperature(temp.toDouble());
      } else if (healthType == 'symptom') {
        final symptoms = lastData['symptoms'] as List?;
        if (symptoms != null) {
          for (final s in symptoms) {
            provider.toggleSymptom(s as String);
          }
        }
      } else if (healthType == 'medication') {
        final med = lastData['medication'] as String?;
        if (med != null) provider.setMedication(med);
      } else if (healthType == 'hospital') {
        final hospital = lastData['hospital_visit'] as String?;
        if (hospital != null) provider.setHospitalVisit(hospital);
      }

      provider.setRecordTime(DateTime.now());

      final activity = await provider.saveHealth();
      if (activity != null && mounted) {
        Navigator.of(context).pop(activity);
      }
    } finally {
      if (mounted) {
        setState(() => _isQuickSaving = false);
      }
    }
  }

  Widget _buildHealthTypeSelector(RecordProvider provider) {
    final l10n = S.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.healthTypeSelectLabel,
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),
        Row(
          children: [
            Expanded(
              child: _HealthTypeButton(
                type: 'temperature',
                label: l10n.healthTypeTemperature,
                icon: LuluIcons.temperature,
                isSelected: provider.healthType == 'temperature',
                onTap: () => provider.setHealthType('temperature'),
              ),
            ),
            const SizedBox(width: LuluSpacing.sm),
            Expanded(
              child: _HealthTypeButton(
                type: 'symptom',
                label: l10n.healthTypeSymptom,
                icon: LuluIcons.symptom,
                isSelected: provider.healthType == 'symptom',
                onTap: () => provider.setHealthType('symptom'),
              ),
            ),
          ],
        ),
        const SizedBox(height: LuluSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _HealthTypeButton(
                type: 'medication',
                label: l10n.healthTypeMedication,
                icon: LuluIcons.medication,
                isSelected: provider.healthType == 'medication',
                onTap: () => provider.setHealthType('medication'),
              ),
            ),
            const SizedBox(width: LuluSpacing.sm),
            Expanded(
              child: _HealthTypeButton(
                type: 'hospital',
                label: l10n.healthTypeHospital,
                icon: LuluIcons.hospital,
                isSelected: provider.healthType == 'hospital',
                onTap: () => provider.setHealthType('hospital'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthTypeContent(RecordProvider provider) {
    switch (provider.healthType) {
      case 'temperature':
        return _buildTemperatureInput(provider);
      case 'symptom':
        return _buildSymptomSelector(provider);
      case 'medication':
        return _buildMedicationInput(provider);
      case 'hospital':
        return _buildHospitalInput(provider);
      default:
        return const SizedBox.shrink();
    }
  }

  /// UX-03: 체온 슬라이더로 변경 (키보드 제거)
  Widget _buildTemperatureInput(RecordProvider provider) {
    return TemperatureSlider(
      value: provider.temperature ?? 36.5,
      onChanged: (temp) {
        provider.setTemperature(temp);
      },
    );
  }

  Widget _buildSymptomSelector(RecordProvider provider) {
    final l10n = S.of(context)!;
    final symptoms = [
      ('cough', l10n.symptomCough, LuluIcons.cough),
      ('runny_nose', l10n.symptomRunnyNose, LuluIcons.runnyNose),
      ('fever', l10n.symptomFever, LuluIcons.fever),
      ('vomiting', l10n.symptomVomiting, LuluIcons.vomiting),
      ('diarrhea', l10n.symptomDiarrhea, LuluIcons.diarrhea),
      ('rash', l10n.symptomRash, LuluIcons.rash),
      ('other', l10n.symptomOther, LuluIcons.other),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.healthSymptomSelectLabel,
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),
        Wrap(
          spacing: LuluSpacing.sm,
          runSpacing: LuluSpacing.sm,
          children: symptoms.map((s) {
            final isSelected = provider.symptoms.contains(s.$1);
            return GestureDetector(
              onTap: () => provider.toggleSymptom(s.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: LuluSpacing.md,
                  vertical: LuluSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? LuluActivityColors.healthBg
                      : LuluColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(LuluRadius.sm),
                  border: Border.all(
                    color: isSelected
                        ? LuluActivityColors.health
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      s.$3,
                      size: 16,
                      color: isSelected
                          ? LuluActivityColors.health
                          : LuluTextColors.secondary,
                    ),
                    const SizedBox(width: LuluSpacing.xs),
                    Text(
                      s.$2,
                      style: LuluTextStyles.labelMedium.copyWith(
                        color: isSelected
                            ? LuluActivityColors.health
                            : LuluTextColors.secondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMedicationInput(RecordProvider provider) {
    final l10n = S.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.healthMedicationInfo,
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
            controller: _medicationController,
            maxLines: 2,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.primary,
            ),
            decoration: InputDecoration(
              hintText: l10n.hintMedication,
              hintStyle: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.tertiary,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              provider.setMedication(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHospitalInput(RecordProvider provider) {
    final l10n = S.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.healthHospitalInfo,
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
            controller: _hospitalController,
            maxLines: 2,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.primary,
            ),
            decoration: InputDecoration(
              hintText: l10n.hintHospital,
              hintStyle: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.tertiary,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              provider.setHospitalVisit(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotesInput() {
    final l10n = S.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.notesOptionalLabel,
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
            maxLines: 2,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.primary,
            ),
            decoration: InputDecoration(
              hintText: l10n.hintAdditionalNotes,
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

  Widget _buildMedicalDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.md),
      decoration: BoxDecoration(
        color: LuluStatusColors.warningSoft,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
        border: Border.all(
          color: LuluStatusColors.warningBorder,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LuluIcons.statusWarn,
            color: LuluStatusColors.warning,
            size: 18,
          ),
          const SizedBox(width: LuluSpacing.sm),
          Expanded(
            child: Text(
              S.of(context)!.medicalDisclaimer,
              style: LuluTextStyles.caption.copyWith(
                color: LuluStatusColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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
          backgroundColor: LuluActivityColors.health,
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
            : Text(
                S.of(context)!.buttonSave,
                style: LuluTextStyles.labelLarge.copyWith(
                  color: Colors.white,
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
    final activity = await provider.saveHealth();
    if (activity != null && mounted) {
      Navigator.of(context).pop(activity);
    }
  }
}

/// 건강 기록 유형 선택 버튼
class _HealthTypeButton extends StatelessWidget {
  final String type;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _HealthTypeButton({
    required this.type,
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
        padding: const EdgeInsets.symmetric(
          vertical: LuluSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluActivityColors.healthBg
              : LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(LuluRadius.md),
          border: Border.all(
            color: isSelected
                ? LuluActivityColors.health
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected
                  ? LuluActivityColors.health
                  : LuluTextColors.secondary,
            ),
            const SizedBox(height: LuluSpacing.sm),
            Text(
              label,
              style: LuluTextStyles.labelMedium.copyWith(
                color: isSelected
                    ? LuluActivityColors.health
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
