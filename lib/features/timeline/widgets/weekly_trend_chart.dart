import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart' show S;

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_shadows.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';

/// 주간 트렌드 차트
///
/// 작업 지시서 v1.0: 심플 막대 차트
/// - 7일간 데이터 표시
/// - 하이라이트 지원
class WeeklyTrendChart extends StatelessWidget {
  final List<double> dailyHours;
  final Color barColor;
  final int? highlightIndex;

  const WeeklyTrendChart({
    super.key,
    required this.dailyHours,
    required this.barColor,
    this.highlightIndex,
  });

  @override
  Widget build(BuildContext context) {
    // 최대값 찾기 (차트 높이 스케일링용)
    final maxValue = dailyHours.isEmpty
        ? 1.0
        : dailyHours.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxValue > 0 ? maxValue : 1.0;

    return Container(
      height: 160,
      padding: const EdgeInsets.all(LuluSpacing.md),
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
      child: Column(
        children: [
          // 차트 영역
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final value = index < dailyHours.length
                    ? dailyHours[index]
                    : 0.0;
                final isHighlighted = highlightIndex == index;

                return Expanded(
                  child: _buildBar(
                    value: value,
                    maxValue: effectiveMax,
                    isHighlighted: isHighlighted,
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: LuluSpacing.sm),

          // 요일 라벨
          _buildDayLabels(context),
        ],
      ),
    );
  }

  /// 막대 빌드
  Widget _buildBar({
    required double value,
    required double maxValue,
    required bool isHighlighted,
  }) {
    // 최소 높이 비율 (값이 0이 아닐 때)
    final heightRatio = value > 0 ? (value / maxValue).clamp(0.05, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 값 라벨 (하이라이트된 경우만)
          if (isHighlighted && value > 0) ...[
            Text(
              value.toStringAsFixed(1),
              style: LuluTextStyles.caption.copyWith(
                color: barColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
          ],

          // 막대
          Flexible(
            child: FractionallySizedBox(
              heightFactor: heightRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? barColor
                      : barColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(LuluRadius.indicator),
                  boxShadow: isHighlighted
                      ? LuluShadows.barGlow(color: barColor)
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabels(BuildContext context) {
    final l10n = S.of(context)!;
    final labels = [
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
      l10n.weekdaySat,
      l10n.weekdaySun,
    ];
    return Row(
      children: labels.map((label) {
        return Expanded(
          child: Text(
            label,
            style: LuluTextStyles.caption.copyWith(
              color: LuluTextColors.tertiary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }
}
