import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/baby_tab_bar.dart';
import '../widgets/growth_number_input.dart';
import '../validators/growth_input_validator.dart';

/// 성장 측정값 입력 화면
///
/// 진입 경로:
/// 1. GrowthScreen → [+ 측정 기록 추가]
/// 2. HomeScreen → QuickRecordFAB → [성장]
/// 3. GrowthChartScreen → [+ 기록]
class GrowthInputScreen extends StatefulWidget {
  final List<BabyModel> babies;
  final String? initialBabyId;
  final GrowthMeasurementModel? previousMeasurement;
  final Function(GrowthMeasurementModel) onSave;

  const GrowthInputScreen({
    super.key,
    required this.babies,
    this.initialBabyId,
    this.previousMeasurement,
    required this.onSave,
  });

  @override
  State<GrowthInputScreen> createState() => _GrowthInputScreenState();
}

class _GrowthInputScreenState extends State<GrowthInputScreen> {
  late List<String> _selectedBabyIds;
  DateTime _measuredAt = DateTime.now();
  double? _weight;
  double? _length;
  double? _headCircumference;
  String? _note;

  bool _isSaving = false;
  String? _warningMessage;

  @override
  void initState() {
    super.initState();
    _selectedBabyIds = widget.initialBabyId != null
        ? [widget.initialBabyId!]
        : widget.babies.isNotEmpty
            ? [widget.babies.first.id]
            : [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuluColors.midnightNavy,
      appBar: AppBar(
        backgroundColor: LuluColors.midnightNavy,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LuluIcons.back, color: LuluTextColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '성장 기록',
          style: LuluTextStyles.titleMedium.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _onSave,
            child: Text(
              '저장하기',
              style: LuluTextStyles.bodyMedium.copyWith(
                color: _canSave()
                    ? LuluColors.lavenderMist
                    : LuluTextColors.tertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LuluSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아기 선택
            if (widget.babies.length > 1) ...[
              BabyTabBar(
                babies: widget.babies,
                selectedBabyId: _selectedBabyIds.isNotEmpty
                    ? _selectedBabyIds.first
                    : null,
                onBabyChanged: (babyId) {
                  if (babyId != null) {
                    setState(() => _selectedBabyIds = [babyId]);
                  }
                },
              ),
              const SizedBox(height: LuluSpacing.xl),
            ],

            // 측정일
            _buildDateSelector(),

            const SizedBox(height: LuluSpacing.lg),

            // 체중 (필수)
            GrowthNumberInput(
              label: '체중',
              icon: LuluIcons.weight,
              unit: 'kg',
              value: _weight,
              previousValue: widget.previousMeasurement?.weightKg,
              previousDate: widget.previousMeasurement?.measuredAt,
              min: 0.3,
              max: 30.0,
              decimalPlaces: 2,
              required: true,
              onChanged: (value) {
                setState(() => _weight = value);
                _checkWarnings();
              },
            ),

            const SizedBox(height: LuluSpacing.lg),

            // 신장 (선택)
            GrowthNumberInput(
              label: '신장',
              icon: LuluIcons.ruler,
              unit: 'cm',
              value: _length,
              previousValue: widget.previousMeasurement?.lengthCm,
              previousDate: widget.previousMeasurement?.measuredAt,
              min: 20.0,
              max: 120.0,
              decimalPlaces: 1,
              required: false,
              onChanged: (value) {
                setState(() => _length = value);
                _checkWarnings();
              },
            ),

            const SizedBox(height: LuluSpacing.lg),

            // 두위 (선택)
            GrowthNumberInput(
              label: '두위',
              icon: LuluIcons.head,
              unit: 'cm',
              value: _headCircumference,
              previousValue: widget.previousMeasurement?.headCircumferenceCm,
              previousDate: widget.previousMeasurement?.measuredAt,
              min: 15.0,
              max: 60.0,
              decimalPlaces: 1,
              required: false,
              onChanged: (value) {
                setState(() => _headCircumference = value);
              },
            ),

            const SizedBox(height: LuluSpacing.lg),

            // 메모 (선택)
            _buildNoteInput(),

            const SizedBox(height: LuluSpacing.lg),

            // 경고 메시지
            if (_warningMessage != null) _buildWarning(),

            const SizedBox(height: LuluSpacing.lg),

            // 팁
            _buildTip(),

            const SizedBox(height: 100), // 키보드 여백
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final formatter = DateFormat('yyyy년 M월 d일', 'ko_KR');
    final isToday = DateUtils.isSameDay(_measuredAt, DateTime.now());

    return Container(
      padding: const EdgeInsets.all(LuluSpacing.lg),
      decoration: BoxDecoration(
        color: LuluColors.deepBlue,
        borderRadius: BorderRadius.circular(LuluRadius.md),
      ),
      child: Row(
        children: [
          Icon(LuluIcons.calendar, size: 18, color: LuluColors.lavenderMist),
          const SizedBox(width: LuluSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '측정일',
                  style: LuluTextStyles.caption.copyWith(
                    color: LuluTextColors.secondary,
                  ),
                ),
                Text(
                  '${formatter.format(_measuredAt)}${isToday ? ' (오늘)' : ''}',
                  style: LuluTextStyles.bodyLarge.copyWith(
                    color: LuluTextColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _selectDate,
            child: Text(
              '변경',
              style: LuluTextStyles.bodyMedium.copyWith(
                color: LuluColors.lavenderMist,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInput() {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.lg),
      decoration: BoxDecoration(
        color: LuluColors.deepBlue,
        borderRadius: BorderRadius.circular(LuluRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LuluIcons.memo, size: 18, color: LuluColors.lavenderMist),
              const SizedBox(width: LuluSpacing.sm),
              Text(
                '메모',
                style: LuluTextStyles.bodyLarge.copyWith(
                  color: LuluTextColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '선택',
                style: LuluTextStyles.caption.copyWith(
                  color: LuluTextColors.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: LuluSpacing.md),
          TextField(
            maxLines: 2,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.primary,
            ),
            decoration: InputDecoration(
              hintText: '소아과 정기검진, 예방접종 등',
              hintStyle: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.tertiary,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) => _note = value,
          ),
        ],
      ),
    );
  }

  Widget _buildWarning() {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.md),
      decoration: BoxDecoration(
        color: LuluStatusColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(LuluRadius.sm),
        border: Border.all(
          color: LuluStatusColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LuluIcons.infoOutline,
            size: 18,
            color: LuluStatusColors.warning,
          ),
          const SizedBox(width: LuluSpacing.sm),
          Expanded(
            child: Text(
              _warningMessage!,
              style: LuluTextStyles.caption.copyWith(
                color: LuluStatusColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip() {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.md),
      decoration: BoxDecoration(
        color: LuluColors.surfaceElevated,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
      child: Row(
        children: [
          Icon(LuluIcons.tips, size: 16, color: LuluColors.champagneGold),
          const SizedBox(width: LuluSpacing.sm),
          Expanded(
            child: Text(
              '소아과 정기검진 후 기록하면 정확해요',
              style: LuluTextStyles.caption.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final selectedBaby = widget.babies.firstWhere(
      (b) => _selectedBabyIds.contains(b.id),
      orElse: () => widget.babies.first,
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: selectedBaby.birthDate,
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: LuluColors.lavenderMist,
              surface: LuluColors.deepBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _measuredAt = picked);
    }
  }

  bool _canSave() {
    return _selectedBabyIds.isNotEmpty && _weight != null && _weight! >= 0.3;
  }

  void _checkWarnings() {
    if (widget.previousMeasurement == null) return;

    final daysDiff =
        _measuredAt.difference(widget.previousMeasurement!.measuredAt).inDays;

    final warning = GrowthInputValidator.checkRapidWeightChange(
      _weight,
      widget.previousMeasurement!.weightKg,
      daysDiff,
    );

    setState(() => _warningMessage = warning);
  }

  void _onSave() async {
    if (!_canSave()) return;

    setState(() => _isSaving = true);

    try {
      // 선택된 아기들에게 각각 기록 생성
      for (final babyId in _selectedBabyIds) {
        final measurement = GrowthMeasurementModel.create(
          babyId: babyId,
          measuredAt: _measuredAt,
          weightKg: _weight!,
          lengthCm: _length,
          headCircumferenceCm: _headCircumference,
          note: _note,
        );
        widget.onSave(measurement);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LuluIcons.checkCircle, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '성장 기록이 저장되었어요',
                  style: LuluTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: LuluStatusColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LuluRadius.sm),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
