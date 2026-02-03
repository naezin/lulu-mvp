import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../../core/utils/recommendation_ranges.dart';

/// 통계 유형
enum StatType {
  sleep,
  feeding,
  diaper,
}

/// 통계 요약 카드
///
/// 작업 지시서 v1.0: 홈 화면 스타일과 통일
/// - 수치 + 단위
/// - 변화량 표시
/// - 권장 범위 뱃지
class StatSummaryCard extends StatelessWidget {
  final StatType type;
  final double value;
  final String unit;
  final double change;
  final int? correctedAgeDays;

  const StatSummaryCard({
    super.key,
    required this.type,
    required this.value,
    required this.unit,
    required this.change,
    this.correctedAgeDays,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final color = _getTypeColor();
    final icon = _getTypeIcon();
    final title = _getTypeTitle(l10n);
    final recommendation = _getRecommendation();

    return Container(
      padding: const EdgeInsets.all(LuluSpacing.md),
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아이콘 + 타이틀
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: LuluSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: LuluTextStyles.caption.copyWith(
                    color: LuluTextColors.secondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: LuluSpacing.sm),

          // 수치
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.toStringAsFixed(1),
                style: LuluTextStyles.titleLarge.copyWith(
                  color: LuluTextColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: LuluTextStyles.bodySmall.copyWith(
                  color: LuluTextColors.secondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: LuluSpacing.xs),

          // 변화량
          _buildChangeIndicator(),

          // 권장 범위 뱃지 (있으면)
          if (recommendation != null) ...[
            const SizedBox(height: LuluSpacing.xs),
            _buildRecommendationBadge(recommendation),
          ],
        ],
      ),
    );
  }

  /// 변화량 표시
  Widget _buildChangeIndicator() {
    if (change == 0) {
      return Text(
        '변동 없음',
        style: LuluTextStyles.caption.copyWith(
          color: LuluTextColors.tertiary,
        ),
      );
    }

    final isPositive = change > 0;
    final icon = isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final color = isPositive ? LuluStatusColors.success : LuluStatusColors.warning;
    final changeText = isPositive ? '+${change.abs().toStringAsFixed(0)}' : '-${change.abs().toStringAsFixed(0)}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          changeText,
          style: LuluTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 권장 범위 뱃지
  Widget _buildRecommendationBadge(RecommendationResult result) {
    final color = switch (result.status) {
      RecommendationStatus.inRange => LuluStatusColors.success,
      RecommendationStatus.belowRange => LuluStatusColors.warning,
      RecommendationStatus.aboveRange => LuluStatusColors.warning,
      RecommendationStatus.unknown => LuluTextColors.tertiary,
    };

    final text = switch (result.status) {
      RecommendationStatus.inRange => '적정',
      RecommendationStatus.belowRange => '적음',
      RecommendationStatus.aboveRange => '많음',
      RecommendationStatus.unknown => '-',
    };

    if (result.status == RecommendationStatus.unknown) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: LuluTextStyles.caption.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 유형별 색상
  Color _getTypeColor() {
    return switch (type) {
      StatType.sleep => LuluActivityColors.sleep,
      StatType.feeding => LuluActivityColors.feeding,
      StatType.diaper => LuluActivityColors.diaper,
    };
  }

  /// 유형별 아이콘
  IconData _getTypeIcon() {
    return switch (type) {
      StatType.sleep => Icons.bedtime_rounded,
      StatType.feeding => Icons.restaurant_rounded,
      StatType.diaper => Icons.baby_changing_station_rounded,
    };
  }

  /// 유형별 타이틀
  String _getTypeTitle(S? l10n) {
    return switch (type) {
      StatType.sleep => l10n?.statsSleep ?? '수면',
      StatType.feeding => l10n?.statsFeeding ?? '수유',
      StatType.diaper => l10n?.statsDiaper ?? '기저귀',
    };
  }

  /// 권장 범위 확인
  RecommendationResult? _getRecommendation() {
    if (correctedAgeDays == null) return null;

    return switch (type) {
      StatType.sleep => RecommendationRanges.checkSleep(
          correctedAgeDays: correctedAgeDays!,
          hoursPerDay: value,
        ),
      StatType.feeding => RecommendationRanges.checkFeeding(
          correctedAgeDays: correctedAgeDays!,
          timesPerDay: value,
        ),
      StatType.diaper => RecommendationRanges.checkDiaper(
          correctedAgeDays: correctedAgeDays!,
          timesPerDay: value,
        ),
    };
  }
}
