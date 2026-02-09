import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/activity_model.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// 개별 빠른 수유 버튼
///
/// HOTFIX v1.2: 최근 수유 기록 빠른 저장
/// - 원탭 저장 (TTC < 2초)
/// - 500ms 롱프레스 → 수정 모드
/// - 56dp 높이, 아이콘 + 라벨
class RecentFeedingButton extends StatelessWidget {
  /// 수유 기록 템플릿
  final ActivityModel record;

  /// 탭 콜백 (빠른 저장)
  final VoidCallback onTap;

  /// 롱프레스 콜백 (수정 모드)
  final VoidCallback onLongPress;

  const RecentFeedingButton({
    super.key,
    required this.record,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;
    final data = record.data;
    final feedingType = data?['feeding_type'] as String? ?? 'bottle';
    final side = data?['breast_side'] as String?;
    final amountMl = data?['amount_ml'];
    final durationMinutes = data?['duration_minutes'];

    return Semantics(
      button: true,
      label: _getAccessibilityLabel(feedingType, side, amountMl, durationMinutes, l10n),
      child: Material(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LuluRadius.sm),
              border: Border.all(color: LuluColors.glassBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 아이콘
                Icon(
                  _getIcon(feedingType, side),
                  size: 20,
                  color: LuluActivityColors.feeding,
                ),
                const SizedBox(width: 8),
                // 라벨
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTypeLabel(feedingType, side, l10n),
                        style: LuluTextStyles.labelSmall.copyWith(
                          color: LuluTextColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _getAmountLabel(feedingType, amountMl, durationMinutes, l10n),
                        style: LuluTextStyles.caption.copyWith(
                          color: LuluTextColors.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String feedingType, String? side) {
    switch (feedingType) {
      case 'breast':
        if (side == 'left') return LuluIcons.back;
        if (side == 'right') return LuluIcons.forward;
        return LuluIcons.compareArrows;
      case 'formula':
      case 'bottle':
        return LuluIcons.feeding;
      case 'solid':
        return LuluIcons.feedingSolid;
      default:
        return LuluIcons.feeding;
    }
  }

  String _getTypeLabel(String feedingType, String? side, S l10n) {
    switch (feedingType) {
      case 'breast':
        if (side == 'left') return l10n.feedingBreastLeft;
        if (side == 'right') return l10n.feedingBreastRight;
        return l10n.feedingBreastBoth;
      case 'formula':
      case 'bottle':
        return l10n.feedingTypeFormula;
      case 'solid':
        return l10n.feedingTypeSolid;
      default:
        return l10n.activityTypeFeeding;
    }
  }

  String _getAmountLabel(
    String feedingType,
    dynamic amountMl,
    dynamic durationMinutes,
    S l10n,
  ) {
    if (feedingType == 'breast' && durationMinutes != null) {
      return l10n.feedingDurationMinutes(durationMinutes as int);
    }
    if (amountMl != null) {
      return l10n.feedingAmountMl((amountMl as num).toInt());
    }
    return '';
  }

  String _getAccessibilityLabel(
    String feedingType,
    String? side,
    dynamic amountMl,
    dynamic durationMinutes,
    S l10n,
  ) {
    final type = _getTypeLabel(feedingType, side, l10n);
    final amount = _getAmountLabel(feedingType, amountMl, durationMinutes, l10n);
    return l10n.recentFeedingAccessibility(type, amount);
  }
}
