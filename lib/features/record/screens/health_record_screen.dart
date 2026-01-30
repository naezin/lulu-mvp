import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_model.dart';
import '../../../data/models/baby_type.dart';
import '../../../shared/widgets/baby_tab_bar.dart';
import '../../../shared/widgets/quick_record_button.dart';
import '../providers/record_provider.dart';
import '../widgets/record_time_picker.dart';

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
  final _temperatureController = TextEditingController();
  final _medicationController = TextEditingController();
  final _hospitalController = TextEditingController();
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
    _temperatureController.dispose();
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
          icon: const Icon(Icons.close, color: LuluTextColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '건강 기록',
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
                        lastRecord: widget.lastHealthRecord,
                        activityType: ActivityType.health,
                        isLoading: _isQuickSaving,
                        onTap: () => _handleQuickSave(provider),
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
                  label: '기록 시간',
                  time: provider.recordTime,
                  onTimeChanged: provider.setRecordTime,
                ),

                const SizedBox(height: LuluSpacing.xxl),

                // 메모
                _buildNotesInput(),

                const SizedBox(height: LuluSpacing.lg),

                // 의료 면책 문구
                _buildMedicalDisclaimer(),

                const SizedBox(height: LuluSpacing.xxl),

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기록 유형 선택',
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
                label: '체온',
                emoji: '🌡️',
                isSelected: provider.healthType == 'temperature',
                onTap: () => provider.setHealthType('temperature'),
              ),
            ),
            const SizedBox(width: LuluSpacing.sm),
            Expanded(
              child: _HealthTypeButton(
                type: 'symptom',
                label: '증상',
                emoji: '🤒',
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
                label: '투약',
                emoji: '💊',
                isSelected: provider.healthType == 'medication',
                onTap: () => provider.setHealthType('medication'),
              ),
            ),
            const SizedBox(width: LuluSpacing.sm),
            Expanded(
              child: _HealthTypeButton(
                type: 'hospital',
                label: '병원방문',
                emoji: '🏥',
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

  Widget _buildTemperatureInput(RecordProvider provider) {
    final temp = provider.temperature;
    final status = _getTemperatureStatus(temp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '체온 (°C)',
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
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _temperatureController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: LuluTextStyles.displaySmall.copyWith(
                    color: LuluTextColors.primary,
                  ),
                  decoration: InputDecoration(
                    hintText: '36.5',
                    hintStyle: LuluTextStyles.displaySmall.copyWith(
                      color: LuluTextColors.tertiary,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    final temp = double.tryParse(value);
                    provider.setTemperature(temp);
                  },
                ),
              ),
              Text(
                '°C',
                style: LuluTextStyles.titleLarge.copyWith(
                  color: LuluTextColors.secondary,
                ),
              ),
            ],
          ),
        ),
        // 체온 상태 표시
        if (temp != null) ...[
          const SizedBox(height: LuluSpacing.md),
          Container(
            padding: const EdgeInsets.all(LuluSpacing.md),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: status.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: LuluSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.label,
                        style: LuluTextStyles.labelMedium.copyWith(
                          color: status.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status.message,
                        style: LuluTextStyles.caption.copyWith(
                          color: status.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSymptomSelector(RecordProvider provider) {
    final symptoms = [
      ('cough', '기침', '🤧'),
      ('runny_nose', '콧물', '🤧'),
      ('fever', '발열', '🤒'),
      ('vomiting', '구토', '🤮'),
      ('diarrhea', '설사', '💩'),
      ('rash', '발진', '🔴'),
      ('other', '기타', '📝'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '증상 선택 (복수 선택 가능)',
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
                  borderRadius: BorderRadius.circular(12),
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
                    Text(s.$3, style: const TextStyle(fontSize: 16)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '투약 정보',
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
            controller: _medicationController,
            maxLines: 2,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.primary,
            ),
            decoration: InputDecoration(
              hintText: '약 이름, 용량, 복용 방법 등',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '병원 방문 정보',
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
            controller: _hospitalController,
            maxLines: 2,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.primary,
            ),
            decoration: InputDecoration(
              hintText: '병원명, 진료 내용, 처방 등',
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
            maxLines: 2,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.primary,
            ),
            decoration: InputDecoration(
              hintText: '추가 메모',
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
        color: LuluColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: LuluTextColors.tertiary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: LuluTextColors.tertiary,
            size: 16,
          ),
          const SizedBox(width: LuluSpacing.sm),
          Expanded(
            child: Text(
              '이 정보는 참고용이며 의료 조언이 아닙니다.\n이상 증상이 있으면 소아과 전문의와 상담하세요.',
              style: LuluTextStyles.caption.copyWith(
                color: LuluTextColors.tertiary,
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
            : Text(
                '저장하기',
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

  _TemperatureStatus _getTemperatureStatus(double? temp) {
    if (temp == null) {
      return _TemperatureStatus(
        color: LuluTextColors.tertiary,
        label: '',
        message: '',
      );
    }

    if (temp < 36.0) {
      return _TemperatureStatus(
        color: LuluStatusColors.info,
        label: '저체온',
        message: '체온이 낮아요. 보온에 신경써주세요.',
      );
    } else if (temp <= 37.5) {
      return _TemperatureStatus(
        color: LuluStatusColors.success,
        label: '정상',
        message: '정상 체온이에요.',
      );
    } else if (temp <= 38.0) {
      return _TemperatureStatus(
        color: LuluStatusColors.warning,
        label: '미열',
        message: '미열이 있어요. 지켜봐주세요.',
      );
    } else {
      return _TemperatureStatus(
        color: LuluStatusColors.error,
        label: '발열',
        message: '열이 있어요. 병원 방문을 권장해요.',
      );
    }
  }

  Future<void> _handleSave(RecordProvider provider) async {
    final activity = await provider.saveHealth();
    if (activity != null && mounted) {
      Navigator.of(context).pop(activity);
    }
  }
}

/// 체온 상태 정보
class _TemperatureStatus {
  final Color color;
  final String label;
  final String message;

  _TemperatureStatus({
    required this.color,
    required this.label,
    required this.message,
  });
}

/// 건강 기록 유형 선택 버튼
class _HealthTypeButton extends StatelessWidget {
  final String type;
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _HealthTypeButton({
    required this.type,
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
        padding: const EdgeInsets.symmetric(
          vertical: LuluSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluActivityColors.healthBg
              : LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? LuluActivityColors.health
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 28),
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
