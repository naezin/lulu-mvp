import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// 아기 필터 탭 위젯
///
/// 작업 지시서 v1.2.1: 아기 필터 탭 + 교정연령 표시
/// [전체] [민지 교정42일] [민정 교정38일] [함께 보기]
class BabyFilterTabs extends StatelessWidget {
  /// 선택된 탭 인덱스
  /// -1: 함께 보기, 0: 전체, 1~n: 개별 아기
  final int selectedIndex;

  /// 아기 목록
  final List<BabyFilterItem> babies;

  /// 교정연령 표시 여부
  final bool showCorrectedAge;

  /// 탭 선택 콜백
  final ValueChanged<int> onChanged;

  const BabyFilterTabs({
    super.key,
    required this.selectedIndex,
    required this.babies,
    this.showCorrectedAge = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 전체 탭
          _buildTab(
            context: context,
            index: 0,
            label: l10n.filterAll,
            isSelected: selectedIndex == 0,
          ),

          const SizedBox(width: 8),

          // 개별 아기 탭들
          ...babies.asMap().entries.map((entry) {
            final index = entry.key + 1; // 1부터 시작
            final baby = entry.value;

            String label = baby.name;
            if (showCorrectedAge && baby.correctedAgeDays != null) {
              label += ' ${l10n.filterCorrectedAgeDays(baby.correctedAgeDays!)}';
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildTab(
                context: context,
                index: index,
                label: label,
                isSelected: selectedIndex == index,
              ),
            );
          }),

          // 함께 보기 탭 (아기 2명 이상일 때만)
          if (babies.length >= 2)
            _buildTab(
              context: context,
              index: -1,
              label: l10n.filterViewTogether,
              isSelected: selectedIndex == -1,
            ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required BuildContext context,
    required int index,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluColors.lavenderMist
              : LuluColors.surfaceCard,
          borderRadius: BorderRadius.circular(LuluRadius.lg),
          border: Border.all(
            color: isSelected
                ? LuluColors.lavenderMist
                : LuluColors.glassBorder,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: LuluTextStyles.labelMedium.copyWith(
              color: isSelected
                  ? LuluColors.midnightNavy
                  : LuluTextColors.secondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// 아기 필터 아이템
class BabyFilterItem {
  final String id;
  final String name;
  final int? correctedAgeDays;

  const BabyFilterItem({
    required this.id,
    required this.name,
    this.correctedAgeDays,
  });
}
