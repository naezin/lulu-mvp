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
    // BUG-004: 아기가 없거나 1명만 있으면 완전히 숨김
    if (babies.length <= 1) {
      return const SizedBox.shrink();
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
  /// 2명: 고정 탭 (Row)
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

  /// 3명 이상: 수평 스크롤 + 스크롤 힌트
  Widget _buildScrollableTabs() {
    return Stack(
      children: [
        SingleChildScrollView(
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
        ),
        // 우측 스크롤 힌트 (페이드 + 화살표)
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    LuluColors.deepBlue.withValues(alpha: 0),
                    LuluColors.deepBlue.withValues(alpha: 0.8),
                    LuluColors.deepBlue,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: LuluTextColors.tertiary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
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
    // SGA-01: 교정연령 또는 SGA 상태 텍스트
    final statusText = baby.statusBadgeText;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        constraints: minWidth != null
            ? BoxConstraints(minWidth: minWidth!)
            : null,
        height: statusText != null ? 56 : 44,
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
          child: statusText != null
              ? _buildTwoLineContent(statusText)
              : _buildSingleLineContent(),
        ),
      ),
    );
  }

  /// 상태 텍스트가 있을 때: 2줄 레이아웃 (SGA-01)
  Widget _buildTwoLineContent(String statusText) {
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // SGA-01: SGA인 경우 아이콘 추가
            if (baby.isSGA) ...[
              Icon(
                Icons.trending_up_rounded,
                size: 10,
                color: isSelected
                    ? (baby.statusBadgeColor ?? color).withValues(alpha: 0.8)
                    : LuluTextColors.tertiary,
              ),
              const SizedBox(width: 2),
            ],
            Text(
              statusText,
              style: LuluTextStyles.caption.copyWith(
                color: isSelected
                    ? color.withValues(alpha: 0.8)
                    : LuluTextColors.tertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 만삭 정상: 1줄 레이아웃 (이름만)
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
}
