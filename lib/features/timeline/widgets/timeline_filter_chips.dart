import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// 타임라인 필터 칩
///
/// Sprint 18-R Phase 3: 활동 유형별 필터링
/// - 전체: 모든 활동
/// - 수유: feeding
/// - 수면: sleep
/// - 기저귀: diaper
/// - 놀이: play
class TimelineFilterChips extends StatelessWidget {
  const TimelineFilterChips({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  /// 현재 선택된 필터 (null = 전체)
  final String? activeFilter;

  /// 필터 변경 콜백
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    final filters = [
      _FilterItem(
        key: null,
        label: l10n?.filterAll ?? 'All',
        icon: LuluIcons.filter,
      ),
      _FilterItem(
        key: 'feeding',
        label: l10n?.activityFeeding ?? 'Feeding',
        icon: LuluIcons.feeding,
        color: LuluActivityColors.feeding,
      ),
      _FilterItem(
        key: 'sleep',
        label: l10n?.activitySleep ?? 'Sleep',
        icon: LuluIcons.sleep,
        color: LuluActivityColors.sleep,
      ),
      _FilterItem(
        key: 'diaper',
        label: l10n?.activityDiaper ?? 'Diaper',
        icon: LuluIcons.diaper,
        color: LuluActivityColors.diaper,
      ),
      _FilterItem(
        key: 'play',
        label: l10n?.activityPlay ?? 'Play',
        icon: LuluIcons.play,
        color: LuluActivityColors.play,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = activeFilter == filter.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
              label: filter.label,
              icon: filter.icon,
              color: filter.color,
              isSelected: isSelected,
              onTap: () {
                if (!isSelected) {
                  HapticFeedback.selectionClick();
                  onFilterChanged(filter.key);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 필터 아이템 데이터
class _FilterItem {
  final String? key;
  final String label;
  final IconData icon;
  final Color? color;

  const _FilterItem({
    required this.key,
    required this.label,
    required this.icon,
    this.color,
  });
}

/// 필터 칩 위젯
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? LuluColors.lavenderMist;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.2)
              : LuluColors.deepBlue,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? chipColor : LuluTextColors.secondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: LuluTextStyles.bodySmall.copyWith(
                color: isSelected ? chipColor : LuluTextColors.secondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
