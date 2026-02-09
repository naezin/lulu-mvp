import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
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

    // Sprint 20 HF #13: i18n 키 기반 메시지 변환
    final localizedMessage = _localizeMessage(context, insight.message);

    return Container(
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(LuluRadius.xs),
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
              localizedMessage,
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

  /// Sprint 20 HF #13: insight 키를 i18n 메시지로 변환
  String _localizeMessage(BuildContext context, String messageKey) {
    final l10n = S.of(context);
    if (l10n == null) return messageKey;

    // 콜론으로 파라미터 분리 (예: 'insight_most_sleep_day:3')
    final parts = messageKey.split(':');
    final key = parts[0];

    switch (key) {
      case 'insight_sleep_increased':
        return l10n.insightSleepIncreased;
      case 'insight_sleep_decreased':
        return l10n.insightSleepDecreased;
      case 'insight_most_sleep_day':
        final dayIndex = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
        final dayName = _getDayName(l10n, dayIndex);
        return l10n.insightMostSleepDay(dayName);
      case 'insight_start_recording':
        return l10n.insightStartRecording;
      default:
        return messageKey;
    }
  }

  /// 요일 인덱스(0=월~6=일)를 i18n 요일명으로 변환
  String _getDayName(S l10n, int dayIndex) {
    switch (dayIndex) {
      case 0:
        return l10n.dayNameMonFull;
      case 1:
        return l10n.dayNameTueFull;
      case 2:
        return l10n.dayNameWedFull;
      case 3:
        return l10n.dayNameThuFull;
      case 4:
        return l10n.dayNameFriFull;
      case 5:
        return l10n.dayNameSatFull;
      case 6:
        return l10n.dayNameSunFull;
      default:
        return l10n.dayNameMonFull;
    }
  }

  IconData _getIcon() {
    switch (insight.type) {
      case InsightType.positive:
        return LuluIcons.tip;
      case InsightType.neutral:
        return LuluIcons.infoOutline;
      case InsightType.attention:
        return LuluIcons.trendingFlat;
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
