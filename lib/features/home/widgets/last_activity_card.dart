import 'package:flutter/material.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';

/// 마지막 활동 카드
///
/// 수유, 수면 등 마지막 활동 정보를 표시
class LastActivityCard extends StatelessWidget {
  final String type; // 'feeding', 'sleep', 'diaper', 'play', 'health'
  final String title;
  final String time;
  final String detail;

  const LastActivityCard({
    super.key,
    required this.type,
    required this.title,
    required this.time,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.lg),
      decoration: BoxDecoration(
        color: LuluColors.deepBlue,
        borderRadius: BorderRadius.circular(LuluRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(_getTypeIcon(), size: 20, color: _getTypeColor()),
              const SizedBox(width: LuluSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: LuluTextStyles.bodySmall.copyWith(
                    color: LuluTextColors.secondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: LuluSpacing.md),

          // 시간
          Text(
            time,
            style: LuluTextStyles.titleMedium.copyWith(
              color: _getTypeColor(),
            ),
          ),

          const SizedBox(height: LuluSpacing.xs),

          // 상세 정보
          Text(
            detail,
            style: LuluTextStyles.bodySmall.copyWith(
              color: LuluTextColors.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (type) {
      case 'feeding':
        return LuluActivityColors.feeding;
      case 'sleep':
        return LuluActivityColors.sleep;
      case 'diaper':
        return LuluActivityColors.diaper;
      case 'play':
        return LuluActivityColors.play;
      case 'health':
        return LuluActivityColors.health;
      default:
        return LuluColors.lavenderMist;
    }
  }

  IconData _getTypeIcon() {
    switch (type) {
      case 'feeding':
        return LuluIcons.feeding;
      case 'sleep':
        return LuluIcons.sleep;
      case 'diaper':
        return LuluIcons.diaper;
      case 'play':
        return LuluIcons.play;
      case 'health':
        return LuluIcons.health;
      default:
        return LuluIcons.other;
    }
  }
}
