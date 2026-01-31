import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/baby_model.dart';
import '../../../data/models/baby_type.dart';
import '../../../data/repositories/baby_repository.dart';

/// 아기 추가 다이얼로그
///
/// 설정 화면에서 새 아기를 추가할 때 사용
class AddBabyDialog extends StatefulWidget {
  final String familyId;
  final List<BabyModel> existingBabies;
  final void Function(BabyModel baby) onBabyAdded;

  const AddBabyDialog({
    super.key,
    required this.familyId,
    required this.existingBabies,
    required this.onBabyAdded,
  });

  @override
  State<AddBabyDialog> createState() => _AddBabyDialogState();
}

class _AddBabyDialogState extends State<AddBabyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();

  DateTime _birthDate = DateTime.now();
  Gender _gender = Gender.unknown;
  int? _gestationalWeeks;
  bool _isPreterm = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LuluColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(LuluSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: LuluColors.lavenderMist.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.child_care_rounded,
                      color: LuluColors.lavenderMist,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: LuluSpacing.md),
                  Text(
                    '아기 추가',
                    style: LuluTextStyles.titleMedium.copyWith(
                      color: LuluTextColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LuluSpacing.lg),

              // 이름 입력
              _buildLabel('이름'),
              const SizedBox(height: LuluSpacing.xs),
              TextFormField(
                controller: _nameController,
                style: LuluTextStyles.bodyLarge.copyWith(
                  color: LuluTextColors.primary,
                ),
                decoration: _inputDecoration('아기 이름을 입력하세요'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: LuluSpacing.md),

              // 생년월일
              _buildLabel('생년월일'),
              const SizedBox(height: LuluSpacing.xs),
              InkWell(
                onTap: _selectBirthDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LuluSpacing.md,
                    vertical: LuluSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: LuluColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: LuluTextColors.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: LuluSpacing.sm),
                      Text(
                        DateFormat('yyyy년 M월 d일').format(_birthDate),
                        style: LuluTextStyles.bodyLarge.copyWith(
                          color: LuluTextColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: LuluSpacing.md),

              // 성별
              _buildLabel('성별'),
              const SizedBox(height: LuluSpacing.xs),
              Row(
                children: [
                  _buildGenderChip('남아', Gender.male),
                  const SizedBox(width: LuluSpacing.sm),
                  _buildGenderChip('여아', Gender.female),
                  const SizedBox(width: LuluSpacing.sm),
                  _buildGenderChip('미정', Gender.unknown),
                ],
              ),
              const SizedBox(height: LuluSpacing.md),

              // 조산아 여부
              _buildLabel('조산아 여부'),
              const SizedBox(height: LuluSpacing.xs),
              SwitchListTile(
                value: _isPreterm,
                onChanged: (value) => setState(() {
                  _isPreterm = value;
                  if (!value) _gestationalWeeks = null;
                }),
                title: Text(
                  '37주 이전에 태어났나요?',
                  style: LuluTextStyles.bodyMedium.copyWith(
                    color: LuluTextColors.primary,
                  ),
                ),
                activeTrackColor: LuluColors.lavenderMist.withValues(alpha: 0.5),
                activeThumbColor: LuluColors.lavenderMist,
                contentPadding: EdgeInsets.zero,
              ),

              // 재태주수 (조산아인 경우)
              if (_isPreterm) ...[
                const SizedBox(height: LuluSpacing.sm),
                _buildLabel('재태주수'),
                const SizedBox(height: LuluSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: LuluSpacing.md),
                  decoration: BoxDecoration(
                    color: LuluColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _gestationalWeeks,
                      isExpanded: true,
                      hint: Text(
                        '주수를 선택하세요',
                        style: LuluTextStyles.bodyMedium.copyWith(
                          color: LuluTextColors.tertiary,
                        ),
                      ),
                      dropdownColor: LuluColors.surfaceElevated,
                      style: LuluTextStyles.bodyLarge.copyWith(
                        color: LuluTextColors.primary,
                      ),
                      items: List.generate(15, (i) => 23 + i)
                          .map((week) => DropdownMenuItem(
                                value: week,
                                child: Text('$week주'),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _gestationalWeeks = value),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: LuluSpacing.md),

              // 출생 체중 (선택)
              _buildLabel('출생 체중 (선택)'),
              const SizedBox(height: LuluSpacing.xs),
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                style: LuluTextStyles.bodyLarge.copyWith(
                  color: LuluTextColors.primary,
                ),
                decoration: _inputDecoration('그램 단위 (예: 2500)'),
              ),
              const SizedBox(height: LuluSpacing.xl),

              // 버튼들
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        '취소',
                        style: LuluTextStyles.labelLarge.copyWith(
                          color: LuluTextColors.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: LuluSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LuluColors.lavenderMist,
                        foregroundColor: LuluColors.midnightNavy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: LuluColors.midnightNavy,
                              ),
                            )
                          : Text(
                              '추가',
                              style: LuluTextStyles.labelLarge.copyWith(
                                color: LuluColors.midnightNavy,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: LuluTextStyles.labelMedium.copyWith(
        color: LuluTextColors.secondary,
      ),
    );
  }

  Widget _buildGenderChip(String label, Gender gender) {
    final isSelected = _gender == gender;
    return Expanded(
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _gender = gender),
        labelStyle: LuluTextStyles.labelMedium.copyWith(
          color: isSelected ? LuluColors.midnightNavy : LuluTextColors.secondary,
        ),
        selectedColor: LuluColors.lavenderMist,
        backgroundColor: LuluColors.surfaceElevated,
        side: BorderSide(
          color: isSelected ? LuluColors.lavenderMist : LuluColors.glassBorder,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: LuluTextStyles.bodyMedium.copyWith(
        color: LuluTextColors.tertiary,
      ),
      filled: true,
      fillColor: LuluColors.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.md,
        vertical: LuluSpacing.md,
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: LuluColors.lavenderMist,
              surface: LuluColors.deepBlue,
              onSurface: LuluTextColors.primary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: LuluColors.midnightNavy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isPreterm && _gestationalWeeks == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('재태주수를 선택해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final birthOrder = widget.existingBabies.length + 1;

      // 다태아 타입 결정
      BabyType? babyType;
      if (widget.existingBabies.isNotEmpty) {
        final totalBabies = birthOrder;
        babyType = switch (totalBabies) {
          2 => BabyType.twin,
          3 => BabyType.triplet,
          4 => BabyType.quadruplet,
          _ => BabyType.singleton,
        };
      }

      final baby = BabyModel(
        id: const Uuid().v4(),
        familyId: widget.familyId,
        name: _nameController.text.trim(),
        birthDate: _birthDate,
        gender: _gender,
        gestationalWeeksAtBirth: _isPreterm ? _gestationalWeeks : null,
        birthWeightGrams: _weightController.text.isNotEmpty
            ? int.tryParse(_weightController.text)
            : null,
        multipleBirthType: babyType,
        birthOrder: birthOrder,
        createdAt: now,
      );

      // DB에 저장
      final savedBaby = await BabyRepository().createBaby(baby);

      if (mounted) {
        widget.onBabyAdded(savedBaby);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('추가 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
