import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// 타임라인 필터 칩
///
/// Sprint 19 Phase 5: 일간/주간 칩 스타일 통일
/// - 아이콘 + 텍스트, 컴팩트 사이즈
/// - 솔리드 선택 배경 (LuluColors.chipXxxBg)
/// - 6개 필터: 전체/수면/수유/기저귀/놀이/건강
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

  static Color _getChipSelectedBg(String? filterValue) {
    switch (filterValue) {
      case 'sleep':
        return LuluColors.chipSleepBg;
      case 'feeding':
        return LuluColors.chipFeedingBg;
      case 'diaper':
        return LuluColors.chipDiaperBg;
      case 'play':
        return LuluColors.chipPlayBg;
      case 'health':
        return LuluColors.chipHealthBg;
      default:
        return LuluColors.chartChipSelectedBg;
    }
  }

  static Color _getChipSelectedBorder(String? filterValue) {
    switch (filterValue) {
      case 'sleep':
        return LuluColors.chipSleepBorder;
      case 'feeding':
        return LuluColors.chipFeedingBorder;
      case 'diaper':
        return LuluColors.chipDiaperBorder;
      case 'play':
        return LuluColors.chipPlayBorder;
      case 'health':
        return LuluColors.chipHealthBorder;
      default:
        return LuluColors.chartChipSelectedBorder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    final filters = [
      (null, l10n?.filterAll ?? 'All', LuluColors.lavenderMist, LuluIcons.filter),
      ('sleep', l10n?.activitySleep ?? 'Sleep', LuluActivityColors.sleep, LuluIcons.sleep),
      ('feeding', l10n?.activityFeeding ?? 'Feeding', LuluActivityColors.feeding, LuluIcons.feeding),
      ('diaper', l10n?.activityDiaper ?? 'Diaper', LuluActivityColors.diaper, LuluIcons.diaper),
      ('play', l10n?.activityPlay ?? 'Play', LuluActivityColors.play, LuluIcons.play),
      ('health', l10n?.activityTypeHealth ?? 'Health', LuluActivityColors.health, LuluIcons.health),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final (filterValue, label, color, icon) = f;
          final isSelected = activeFilter == filterValue;

          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () {
                if (!isSelected) {
                  HapticFeedback.selectionClick();
                  onFilterChanged(filterValue);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _getChipSelectedBg(filterValue)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(LuluRadius.sm),
                  border: Border.all(
                    color: isSelected
                        ? _getChipSelectedBorder(filterValue)
                        : LuluColors.glassBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: isSelected ? color : LuluTextColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? color : LuluTextColors.secondary,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
