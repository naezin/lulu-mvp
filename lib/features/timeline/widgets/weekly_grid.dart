import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../models/day_timeline.dart';

/// 주간 요약 그리드 (2x2)
///
/// Sprint 19: StatSummaryCard(1x3) 대체
/// DailyGrid와 동일한 디자인 (컬러 보더, 아이콘 박스, 폰트 계층)
class WeeklyGrid extends StatelessWidget {
  final WeeklySummary summary;

  const WeeklyGrid({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    // padding 제거 — 부모(weekly_view.dart)에서 이미 LuluSpacing.md 적용됨
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: LuluSpacing.sm,
      crossAxisSpacing: LuluSpacing.sm,
      childAspectRatio: 1.4,
      children: [
        // 평균 수면
        _buildCell(
          context: context,
          icon: LuluIcons.sleep,
          color: LuluActivityColors.sleep,
          title: l10n?.weeklyGridAvgSleep ?? 'Avg Sleep',
          value: summary.avgSleepHours.toStringAsFixed(1),
          unit: l10n?.dailyGridUnitHours ?? 'h',
          trends: [
            if (summary.sleepTrend.abs() >= 0.1)
              _TrendData(summary.sleepTrend, 'h'),
          ],
        ),
        // 평균 수유 — v4: ml + 횟수 동등 나열 + 트렌드 2줄
        _buildFeedingCell(context),
        // 평균 기저귀
        _buildCell(
          context: context,
          icon: LuluIcons.diaper,
          color: LuluActivityColors.diaper,
          title: l10n?.weeklyGridAvgDiaper ?? 'Avg Diaper',
          value: summary.avgDiaperCount.toStringAsFixed(1),
          unit: l10n?.dailyGridCountUnit ?? 'times',
          trends: [
            if (summary.diaperTrend.abs() >= 0.1)
              _TrendData(summary.diaperTrend, ''),
          ],
        ),
        // 평균 놀이
        _buildCell(
          context: context,
          icon: LuluIcons.play,
          color: LuluActivityColors.play,
          title: l10n?.weeklyGridAvgPlay ?? 'Avg Play',
          value: summary.avgPlayMinutes > 60
              ? (summary.avgPlayMinutes / 60).toStringAsFixed(1)
              : summary.avgPlayMinutes.toStringAsFixed(0),
          unit: summary.avgPlayMinutes > 60
              ? (l10n?.dailyGridUnitHours ?? 'h')
              : (l10n?.dailyGridUnitMinutes ?? 'm'),
          trends: [
            if (summary.playTrend.abs() >= 0.1)
              _TrendData(summary.playTrend, 'm'),
          ],
        ),
      ],
    );
  }

  /// v4: 수유 카드 — ml + 횟수 동등 나열 + 트렌드 2줄
  Widget _buildFeedingCell(BuildContext context) {
    final l10n = S.of(context);
    final color = LuluActivityColors.feeding;

    // ml > 0: "685 ml (4.8회)" / ml == 0 (모유만): "4.8 회"
    final valueText = summary.avgFeedingMl > 0
        ? '${summary.avgFeedingMl.toStringAsFixed(0)} ml'
        : summary.avgFeedingCount.toStringAsFixed(1);
    final unitText = summary.avgFeedingMl > 0
        ? '(${summary.avgFeedingCount.toStringAsFixed(1)}${l10n?.dailyGridCountUnit ?? ''})'
        : (l10n?.dailyGridCountUnit ?? 'times');

    return _buildCell(
      context: context,
      icon: LuluIcons.feeding,
      color: color,
      title: l10n?.weeklyGridAvgFeeding ?? 'Avg Feeding',
      value: valueText,
      unit: unitText,
      trends: [
        // v4: 수유량 변동 + 수유횟수 변동 2줄 모두 표시
        if (summary.feedingMlTrend.abs() >= 0.1)
          _TrendData(summary.feedingMlTrend, 'ml'),
        if (summary.feedingCountTrend.abs() >= 0.1)
          _TrendData(summary.feedingCountTrend, ''),
      ],
    );
  }

  /// v4: 앱 공통 패턴 (배경 10%, 보더 30%, 아이콘 배경 20%)
  Widget _buildCell({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    String? unit,
    required List<_TrendData> trends,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),           // v4: 카드 배경 10%
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),         // v4: 보더 30%
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1행: 아이콘(컬러 배경 박스) + 레이블
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),  // v4: 아이콘 배경 20%
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: LuluTextColors.primary.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 2행: 숫자(크게) + 단위(작게)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: LuluTextColors.primary,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: LuluTextColors.secondary,
                  ),
                ),
              ],
            ],
          ),
          // 3행: 추세 — 항상 고정 높이 유지 (정렬 일관성)
          const SizedBox(height: 4),
          SizedBox(
            height: 20,  // 항상 20px 높이 확보 (값 없어도 정렬 유지)
            child: trends.isNotEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final trend in trends)
                        _buildTrendRow(trend.value, trend.unit),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// 추세 행 렌더링
  Widget _buildTrendRow(double trend, String unit) {
    final isUp = trend > 0;
    final arrow = isUp ? '↑' : '↓';
    final color = isUp ? const Color(0xFF6BC48A) : const Color(0xFFE57373);
    return Text(
      '$arrow${trend.abs().toStringAsFixed(1)}$unit',
      style: TextStyle(color: color, fontSize: 11),
    );
  }
}

/// 트렌드 데이터
class _TrendData {
  final double value;
  final String unit;
  const _TrendData(this.value, this.unit);
}
