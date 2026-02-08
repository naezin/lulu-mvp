import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/feeding_type.dart';

/// 수유 종류 선택 위젯 v2.0
///
/// Phase A: 단일 선택 (모유/분유/이유식)
/// Phase B: 복수 선택 지원 (혼합수유) - 추후 구현
///
/// 변경사항 (v2.0):
/// - String 기반 → FeedingContentType enum 기반
/// - 4가지 → 3가지로 정리 (breast+bottle → breastMilk)
/// - 모유 선택 시 직접/유축 세부 선택은 BreastFeedingForm에서 처리
class FeedingTypeSelector extends StatelessWidget {
  final FeedingContentType selectedType;
  final ValueChanged<FeedingContentType> onTypeChanged;

  const FeedingTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '어떤 수유인가요?',
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ContentTypeButton(
                  icon: LuluIcons.feedingBreast,
                  label: '모유',
                  subLabel: '(직접/유축)',
                  isSelected: selectedType == FeedingContentType.breastMilk,
                  onTap: () => onTypeChanged(FeedingContentType.breastMilk),
                ),
              ),
              const SizedBox(width: LuluSpacing.sm),
              Expanded(
                child: _ContentTypeButton(
                  icon: LuluIcons.feedingBottle,
                  label: '분유',
                  subLabel: null,
                  isSelected: selectedType == FeedingContentType.formula,
                  onTap: () => onTypeChanged(FeedingContentType.formula),
                ),
              ),
              const SizedBox(width: LuluSpacing.sm),
              Expanded(
                child: _ContentTypeButton(
                  icon: LuluIcons.feedingSolid,
                  label: '이유식',
                  subLabel: null,
                  isSelected: selectedType == FeedingContentType.solid,
                  onTap: () => onTypeChanged(FeedingContentType.solid),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContentTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _ContentTypeButton({
    required this.icon,
    required this.label,
    this.subLabel,
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
          vertical: LuluSpacing.md,
          horizontal: LuluSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluActivityColors.feedingBg
              : LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          border: Border.all(
            color:
                isSelected ? LuluActivityColors.feeding : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected
                  ? LuluActivityColors.feeding
                  : LuluTextColors.secondary,
            ),
            const SizedBox(height: LuluSpacing.xs),
            Text(
              label,
              style: LuluTextStyles.bodyMedium.copyWith(
                color: isSelected
                    ? LuluTextColors.primary
                    : LuluTextColors.secondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (subLabel != null)
              Text(
                subLabel!,
                style: LuluTextStyles.caption.copyWith(
                  color: LuluTextColors.tertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Legacy 호환성을 위한 래퍼 (임시)
// FeedingRecordScreen 전체 리팩토링 전까지 사용
// ============================================

/// Legacy FeedingTypeSelector (String 기반)
///
/// @deprecated v2.0에서는 FeedingTypeSelector 사용 권장
class LegacyFeedingTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;

  const LegacyFeedingTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 기존 String → FeedingContentType 변환
    FeedingContentType contentType;
    switch (selectedType) {
      case 'breast':
      case 'bottle':
        contentType = FeedingContentType.breastMilk;
        break;
      case 'formula':
        contentType = FeedingContentType.formula;
        break;
      case 'solid':
        contentType = FeedingContentType.solid;
        break;
      default:
        contentType = FeedingContentType.formula;
    }

    return FeedingTypeSelector(
      selectedType: contentType,
      onTypeChanged: (type) {
        // FeedingContentType → 기존 String 변환
        onTypeChanged(type.legacyValue);
      },
    );
  }
}
