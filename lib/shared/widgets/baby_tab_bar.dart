import 'package:flutter/material.dart';
import '../../core/design_system/lulu_colors.dart';
import '../../core/design_system/lulu_typography.dart';
import '../../core/design_system/lulu_spacing.dart';
import '../../data/models/baby_model.dart';

/// 아기 전환 탭바 (Sprint 6 리디자인)
///
/// MVP-F 확정 UX:
/// - 교정연령 통합 표시 ("서준이\n교정 45일")
/// - 3+ 아기 시 수평 스크롤
/// - "둘 다" 버튼 제거 (F-3 확정)
/// - 탭 전환 애니메이션 (300ms ease-out)
class BabyTabBar extends StatelessWidget {
  final List<BabyModel> babies;
  final String? selectedBabyId;
  final ValueChanged<String?> onBabyChanged;

  /// @deprecated F-3 확정으로 "둘 다" 옵션 제거됨
  /// 하위 호환성을 위해 유지하되 무시됨
  final bool showAllOption;

  const BabyTabBar({
    super.key,
    required this.babies,
    required this.selectedBabyId,
    required this.onBabyChanged,
    @Deprecated('F-3 확정으로 "둘 다" 옵션 제거됨')
    this.showAllOption = false,
  });

  @override
  Widget build(BuildContext context) {
    // 아기가 없거나 1명만 있으면 표시하지 않음
    if (babies.isEmpty) {
      return const SizedBox.shrink();
    }

    // 단태아: 교정연령 정보만 표시 (탭 전환 불필요)
    if (babies.length == 1) {
      return _buildSingleBabyHeader(babies.first);
    }

    // 다태아: 탭 형태로 표시
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.lg,
        vertical: LuluSpacing.sm,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LuluColors.deepBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: babies.length <= 2
          ? _buildFixedTabs()
          : _buildScrollableTabs(),
    );
  }

  /// 단태아용 헤더 (교정연령만 표시)
  Widget _buildSingleBabyHeader(BabyModel baby) {
    final correctedAgeText = _getCorrectedAgeText(baby);

    if (correctedAgeText == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.lg,
        vertical: LuluSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.md,
        vertical: LuluSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: LuluColors.deepBlue.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: LuluColors.baby1Color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: LuluSpacing.sm),
          Text(
            correctedAgeText,
            style: LuluTextStyles.caption.copyWith(
              color: LuluTextColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 2명 이하: 고정 탭 (Row)
  Widget _buildFixedTabs() {
    return Row(
      children: babies.map((baby) {
        return Expanded(
          child: _BabyTab(
            baby: baby,
            isSelected: selectedBabyId == baby.id,
            color: _getBabyColor(baby.birthOrder ?? 1),
            onTap: () => onBabyChanged(baby.id),
          ),
        );
      }).toList(),
    );
  }

  /// 3명 이상: 수평 스크롤
  Widget _buildScrollableTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: babies.map((baby) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _BabyTab(
              baby: baby,
              isSelected: selectedBabyId == baby.id,
              color: _getBabyColor(baby.birthOrder ?? 1),
              onTap: () => onBabyChanged(baby.id),
              minWidth: 100,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 교정연령 텍스트 생성
  String? _getCorrectedAgeText(BabyModel baby) {
    if (!baby.isPreterm) return null;

    final correctedWeeks = baby.correctedAgeInWeeks;
    if (correctedWeeks == null) return null;

    final days = correctedWeeks * 7;
    return '교정 $days일';
  }

  /// 아기별 색상 (성별 고정관념 없는 중립 색상)
  Color _getBabyColor(int birthOrder) {
    return LuluColors.getBabyColor(birthOrder - 1);
  }
}

/// 개별 아기 탭
class _BabyTab extends StatelessWidget {
  final BabyModel baby;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final double? minWidth;

  const _BabyTab({
    required this.baby,
    required this.isSelected,
    required this.color,
    required this.onTap,
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    final correctedAgeText = _getCorrectedAgeText();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        constraints: minWidth != null
            ? BoxConstraints(minWidth: minWidth!)
            : null,
        height: correctedAgeText != null ? 56 : 44,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: LuluSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: correctedAgeText != null
              ? _buildTwoLineContent(correctedAgeText)
              : _buildSingleLineContent(),
        ),
      ),
    );
  }

  /// 교정연령이 있을 때: 2줄 레이아웃
  Widget _buildTwoLineContent(String correctedAgeText) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          baby.name,
          style: LuluTextStyles.bodyMedium.copyWith(
            color: isSelected ? color : LuluTextColors.secondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          correctedAgeText,
          style: LuluTextStyles.caption.copyWith(
            color: isSelected
                ? color.withValues(alpha: 0.8)
                : LuluTextColors.tertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  /// 만삭아: 1줄 레이아웃 (이름만)
  Widget _buildSingleLineContent() {
    return Text(
      baby.name,
      style: LuluTextStyles.bodyMedium.copyWith(
        color: isSelected ? color : LuluTextColors.secondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 교정연령 텍스트 생성
  String? _getCorrectedAgeText() {
    if (!baby.isPreterm) return null;

    final correctedWeeks = baby.correctedAgeInWeeks;
    if (correctedWeeks == null) return null;

    final days = correctedWeeks * 7;
    return '교정 $days일';
  }
}
