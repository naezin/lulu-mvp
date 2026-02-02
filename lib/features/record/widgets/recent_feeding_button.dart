import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/activity_model.dart';

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
    final data = record.data;
    final feedingType = data?['feeding_type'] as String? ?? 'bottle';
    final side = data?['breast_side'] as String?;
    final amountMl = data?['amount_ml'];
    final durationMinutes = data?['duration_minutes'];

    return Semantics(
      button: true,
      label: _getAccessibilityLabel(feedingType, side, amountMl, durationMinutes),
      child: Material(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
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
                        _getTypeLabel(feedingType, side),
                        style: LuluTextStyles.labelSmall.copyWith(
                          color: LuluTextColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _getAmountLabel(feedingType, amountMl, durationMinutes),
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
        if (side == 'left') return Icons.arrow_back_rounded;
        if (side == 'right') return Icons.arrow_forward_rounded;
        return Icons.compare_arrows_rounded;
      case 'formula':
      case 'bottle':
        return Icons.local_drink_rounded;
      case 'solid':
        return Icons.restaurant_rounded;
      default:
        return Icons.local_drink_rounded;
    }
  }

  String _getTypeLabel(String feedingType, String? side) {
    switch (feedingType) {
      case 'breast':
        if (side == 'left') return '모유 좌측';
        if (side == 'right') return '모유 우측';
        return '모유 양쪽';
      case 'formula':
      case 'bottle':
        return '분유';
      case 'solid':
        return '이유식';
      default:
        return '수유';
    }
  }

  String _getAmountLabel(
    String feedingType,
    dynamic amountMl,
    dynamic durationMinutes,
  ) {
    if (feedingType == 'breast' && durationMinutes != null) {
      return '$durationMinutes분';
    }
    if (amountMl != null) {
      return '${(amountMl as num).toInt()}ml';
    }
    return '';
  }

  String _getAccessibilityLabel(
    String feedingType,
    String? side,
    dynamic amountMl,
    dynamic durationMinutes,
  ) {
    final type = _getTypeLabel(feedingType, side);
    final amount = _getAmountLabel(feedingType, amountMl, durationMinutes);
    return '$type $amount 빠른 저장 버튼. 길게 누르면 수정 모드';
  }
}
