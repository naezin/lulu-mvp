import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../models/insight_data.dart';

/// AI 인사이트 카드 위젯
///
/// 작업 지시서 v1.2.1: 인사이트 표시 (좋다/나쁘다 표현 없음)
class InsightCard extends StatelessWidget {
  /// 인사이트 데이터
  final InsightData insight;

  /// 컴팩트 모드 (리포트 카드 내부용)
  final bool compact;

  const InsightCard({
    super.key,
    required this.insight,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (insight.message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getIcon(),
            size: compact ? 16 : 20,
            color: _getIconColor(),
          ),
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: Text(
              insight.message,
              style: (compact ? LuluTextStyles.caption : LuluTextStyles.bodySmall)
                  .copyWith(
                color: LuluTextColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (insight.type) {
      case InsightType.positive:
        return Icons.lightbulb_outline;
      case InsightType.neutral:
        return Icons.info_outline;
      case InsightType.attention:
        return Icons.trending_flat;
    }
  }

  Color _getIconColor() {
    switch (insight.type) {
      case InsightType.positive:
        return const Color(0xFFFBBF24); // warning yellow
      case InsightType.neutral:
        return LuluTextColors.secondary;
      case InsightType.attention:
        return const Color(0xFF60A5FA); // info blue
    }
  }

  Color _getBackgroundColor() {
    switch (insight.type) {
      case InsightType.positive:
        return const Color(0xFFFBBF24).withValues(alpha: 0.1);
      case InsightType.neutral:
        return LuluColors.surfaceCard;
      case InsightType.attention:
        return const Color(0xFF60A5FA).withValues(alpha: 0.1);
    }
  }

  Color _getBorderColor() {
    switch (insight.type) {
      case InsightType.positive:
        return const Color(0xFFFBBF24).withValues(alpha: 0.3);
      case InsightType.neutral:
        return LuluColors.glassBorder;
      case InsightType.attention:
        return const Color(0xFF60A5FA).withValues(alpha: 0.3);
    }
  }
}
