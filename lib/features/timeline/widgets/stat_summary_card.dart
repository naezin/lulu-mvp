import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../../core/utils/recommendation_ranges.dart';

/// 통계 유형
enum StatType {
  sleep,
  feeding,
  diaper,
  play,
  wakeWindow,
}

/// 통계 요약 카드
///
/// 작업 지시서 v1.0: 홈 화면 스타일과 통일
/// - 수치 + 단위
/// - 변화량 표시
/// - 권장 범위 뱃지
/// FIX: Sprint 19 E: 수유 카드에 ml 표시 추가
class StatSummaryCard extends StatelessWidget {
  final StatType type;
  final double value;
  final String unit;
  final double change;
  final int? correctedAgeDays;

  /// FIX: Sprint 19 E: 수유 ml 표시용
  final double? feedingMl;
  final double? feedingCount;

  const StatSummaryCard({
    super.key,
    required this.type,
    required this.value,
    required this.unit,
    required this.change,
    this.correctedAgeDays,
    this.feedingMl,
    this.feedingCount,
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
        borderRadius: BorderRadius.circular(LuluRadius.sm),
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
                  borderRadius: BorderRadius.circular(LuluRadius.xs),
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

          // 수치 - FIX: Sprint 19 E: 수유 ml 표시
          _buildValueDisplay(),

          const SizedBox(height: LuluSpacing.xs),

          // 변화량
          _buildChangeIndicator(l10n),

          // 권장 범위 뱃지 (있으면)
          if (recommendation != null) ...[
            const SizedBox(height: LuluSpacing.xs),
            _buildRecommendationBadge(recommendation, l10n),
          ],
        ],
      ),
    );
  }

  /// FIX: Sprint 19 E: 수치 표시 (수유는 ml + 회수)
  Widget _buildValueDisplay() {
    // 수유이고 ml 데이터가 있으면 "685 ml (8.3회)" 형식
    if (type == StatType.feeding && feedingMl != null && feedingMl! > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                feedingMl!.toStringAsFixed(0),
                style: LuluTextStyles.titleLarge.copyWith(
                  color: LuluTextColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                'ml',
                style: LuluTextStyles.bodySmall.copyWith(
                  color: LuluTextColors.secondary,
                ),
              ),
            ],
          ),
          if (feedingCount != null && feedingCount! > 0)
            Text(
              '(${feedingCount!.toStringAsFixed(1)}$unit)',
              style: LuluTextStyles.caption.copyWith(
                color: LuluTextColors.tertiary,
              ),
            ),
        ],
      );
    }

    // 기본 표시: value + unit
    return Row(
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
    );
  }

  /// 변화량 표시
  /// HF2-5: 단위 포함 + 수면은 분→시간 변환
  Widget _buildChangeIndicator(S? l10n) {
    if (change == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LuluIcons.forward,
            size: 12,
            color: LuluTextColors.tertiary,
          ),
          const SizedBox(width: 2),
          Text(
            l10n?.vsPrev ?? 'vs prev',
            style: LuluTextStyles.caption.copyWith(
              color: LuluTextColors.tertiary,
            ),
          ),
        ],
      );
    }

    final isPositive = change > 0;
    final icon = isPositive ? LuluIcons.arrowUp : LuluIcons.arrowDown;
    final color = isPositive ? LuluStatusColors.success : LuluStatusColors.warning;

    // HF2-5: 타입별 단위 포함한 변화량 텍스트
    final changeText = _formatChangeText(change, isPositive);

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

  /// HF2-5: 변화량 텍스트 포맷 (단위 포함)
  String _formatChangeText(double change, bool isPositive) {
    final sign = isPositive ? '+' : '-';
    final absChange = change.abs();

    switch (type) {
      case StatType.sleep:
        // 분 단위로 들어오면 시간으로 변환
        if (absChange > 60) {
          // 분 단위로 간주 → 시간 변환
          final hours = absChange / 60;
          return '$sign${hours.toStringAsFixed(1)}h';
        } else {
          // 시간 단위로 간주
          return '$sign${absChange.toStringAsFixed(1)}h';
        }
      case StatType.feeding:
      case StatType.diaper:
        // 회 단위
        return '$sign${absChange.toStringAsFixed(0)}';
      case StatType.play:
      case StatType.wakeWindow:
        // 분 단위
        return '$sign${absChange.toStringAsFixed(0)}m';
    }
  }

  /// 권장 범위 뱃지
  Widget _buildRecommendationBadge(RecommendationResult result, S? l10n) {
    final color = switch (result.status) {
      RecommendationStatus.inRange => LuluStatusColors.success,
      RecommendationStatus.belowRange => LuluStatusColors.warning,
      RecommendationStatus.aboveRange => LuluStatusColors.warning,
      RecommendationStatus.unknown => LuluTextColors.tertiary,
    };

    final text = switch (result.status) {
      RecommendationStatus.inRange => l10n?.recommendationInRange ?? 'Normal',
      RecommendationStatus.belowRange => l10n?.recommendationBelow ?? 'Low',
      RecommendationStatus.aboveRange => l10n?.recommendationAbove ?? 'High',
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
        borderRadius: BorderRadius.circular(LuluRadius.indicator),
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
      StatType.play => LuluActivityColors.play,
      StatType.wakeWindow => LuluActivityColors.wakeWindow,
    };
  }

  /// 유형별 아이콘
  IconData _getTypeIcon() {
    return switch (type) {
      StatType.sleep => LuluIcons.sleep,
      StatType.feeding => LuluIcons.feedingSolid,
      StatType.diaper => LuluIcons.diaper,
      StatType.play => LuluIcons.play,
      StatType.wakeWindow => LuluIcons.wakeWindow,
    };
  }

  /// 유형별 타이틀
  /// HF2-5: "일평균" 접두어 추가
  String _getTypeTitle(S? l10n) {
    final prefix = l10n?.statsDailyAvg ?? 'Daily Avg';
    return switch (type) {
      StatType.sleep => '$prefix ${l10n?.statsSleep ?? 'Sleep'}',
      StatType.feeding => '$prefix ${l10n?.statsFeeding ?? 'Feeding'}',
      StatType.diaper => '$prefix ${l10n?.statsDiaper ?? 'Diaper'}',
      StatType.play => '$prefix ${l10n?.activityTypePlay ?? 'Play'}',
      StatType.wakeWindow => '$prefix ${l10n?.wakeWindowLabel ?? 'Awake Time'}',
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
      StatType.play => null, // 놀이는 권장 범위 없음
      StatType.wakeWindow => null, // 깨시는 참고 범위 별도 표시
    };
  }
}
