import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../statistics/models/insight_data.dart';

/// Sprint 19 v4: 주간 인사이트 위젯
///
/// - AI 기반 인사이트 표시
/// - v4 디자인 패턴: 배경 10%, 보더 30%
/// - InsightType에 따른 색상 분기
class WeeklyInsight extends StatelessWidget {
  final InsightData insight;

  const WeeklyInsight({
    super.key,
    required this.insight,
  });

  @override
  Widget build(BuildContext context) {
    // 메시지가 비어있으면 표시하지 않음
    if (insight.message.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = _getInsightColor();

    return Container(
      padding: const EdgeInsets.all(LuluSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),          // v4: 배경 10%
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),        // v4: 보더 30%
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아이콘
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),    // v4: 아이콘 배경 20%
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getInsightIcon(),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: LuluSpacing.sm),
          // 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getInsightTitle(context),
                  style: LuluTextStyles.labelMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: LuluTextStyles.bodyMedium.copyWith(
                    color: LuluTextColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 인사이트 유형에 따른 색상
  Color _getInsightColor() {
    switch (insight.type) {
      case InsightType.positive:
        return LuluStatusColors.success;
      case InsightType.attention:
        return LuluStatusColors.warning;
      case InsightType.neutral:
        return LuluColors.lavenderMist;
    }
  }

  /// 인사이트 유형에 따른 아이콘
  IconData _getInsightIcon() {
    switch (insight.type) {
      case InsightType.positive:
        return LuluIcons.checkCircle;
      case InsightType.attention:
        return LuluIcons.statusWarn; // warningAmber 대신
      case InsightType.neutral:
        return LuluIcons.tip;
    }
  }

  /// 인사이트 유형에 따른 타이틀 (i18n 적용)
  String _getInsightTitle(BuildContext context) {
    final l10n = S.of(context);
    switch (insight.type) {
      case InsightType.positive:
        return l10n?.insightTitleGood ?? 'Good news!';
      case InsightType.attention:
        return l10n?.insightTitleCaution ?? 'Note';
      case InsightType.neutral:
        return l10n?.insightTitleDefault ?? 'Weekly insight';
    }
  }
}

/// 다태아 함께보기 인사이트
class TogetherInsight extends StatelessWidget {
  final TogetherInsightData insight;

  const TogetherInsight({
    super.key,
    required this.insight,
  });

  @override
  Widget build(BuildContext context) {
    // 메시지가 비어있으면 표시하지 않음
    if (insight.message.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = LuluColors.lavenderMist;

    return Container(
      padding: const EdgeInsets.all(LuluSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),          // v4: 배경 10%
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),        // v4: 보더 30%
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LuluIcons.switchBaby, // compareArrows 대신
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: LuluSpacing.sm),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final l10n = S.of(context);
                    return Text(
                      l10n?.insightTitleTogether ?? 'Together insight',
                      style: LuluTextStyles.labelMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: LuluSpacing.sm),
          // 메시지
          Text(
            insight.message,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.primary,
            ),
          ),
          const SizedBox(height: LuluSpacing.sm),
          // 아기별 설명 (비교 금지 - 각자 특성만)
          Row(
            children: [
              Expanded(
                child: _BabyInsightChip(
                  name: insight.baby1Name,
                  description: insight.baby1Description,
                  color: LuluColors.babyColors[0],
                ),
              ),
              const SizedBox(width: LuluSpacing.sm),
              Expanded(
                child: _BabyInsightChip(
                  name: insight.baby2Name,
                  description: insight.baby2Description,
                  color: LuluColors.babyColors[1],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 아기별 인사이트 칩 (비교 없이 개별 특성만)
class _BabyInsightChip extends StatelessWidget {
  final String name;
  final String description;
  final Color color;

  const _BabyInsightChip({
    required this.name,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: LuluTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: LuluTextStyles.caption.copyWith(
              color: LuluTextColors.secondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
