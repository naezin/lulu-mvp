import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../models/day_timeline.dart';

/// WeeklyGrid - 주간 요약 2x2 그리드
///
/// Sprint 19: 주간 뷰 재설계
/// - 수면: 일평균 시간 + 트렌드
/// - 수유: 일평균 횟수 + 간격 트렌드
/// - 기저귀: 일평균 횟수
/// - 놀이: 일평균 시간
///
/// 레이아웃: DailyGrid와 동일한 2x2 구조
class WeeklyGrid extends StatelessWidget {
  final WeeklySummary weeklySummary;

  const WeeklyGrid({
    super.key,
    required this.weeklySummary,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.md,
        vertical: LuluSpacing.sm,
      ),
      child: Column(
        children: [
          // 첫째 줄: 수면 + 수유
          Row(
            children: [
              Expanded(
                child: _SleepCard(
                  avgHours: weeklySummary.avgSleepHours,
                  trend: weeklySummary.sleepTrend,
                  l10n: l10n,
                ),
              ),
              const SizedBox(width: LuluSpacing.sm),
              Expanded(
                child: _FeedingCard(
                  avgCount: weeklySummary.avgFeedCount,
                  avgGap: weeklySummary.avgFeedGap,
                  gapTrend: weeklySummary.feedGapTrend,
                  l10n: l10n,
                ),
              ),
            ],
          ),
          const SizedBox(height: LuluSpacing.sm),
          // 둘째 줄: 기저귀 + 놀이
          Row(
            children: [
              Expanded(
                child: _DiaperCard(
                  avgCount: weeklySummary.avgDiapers,
                  l10n: l10n,
                ),
              ),
              const SizedBox(width: LuluSpacing.sm),
              Expanded(
                child: _PlayCard(
                  avgMinutes: weeklySummary.avgPlayMinutes,
                  l10n: l10n,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 기본 카드 위젯 (컴팩트 버전)
class _CompactCard extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final String label;
  final String value;
  final String? trendText;
  final bool? isPositiveTrend;

  const _CompactCard({
    required this.accentColor,
    required this.icon,
    required this.label,
    required this.value,
    this.trendText,
    this.isPositiveTrend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.sm),
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: accentColor,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon + Label
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: accentColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: LuluTextStyles.caption.copyWith(
                    color: LuluTextColors.tertiary,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Value
          Text(
            value,
            style: LuluTextStyles.labelLarge.copyWith(
              color: LuluTextColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Trend (optional)
          if (trendText != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                if (isPositiveTrend != null)
                  Icon(
                    isPositiveTrend! ? Icons.trending_up : Icons.trending_down,
                    size: 10,
                    color: isPositiveTrend!
                        ? LuluStatusColors.success
                        : LuluStatusColors.warning,
                  ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    trendText!,
                    style: LuluTextStyles.caption.copyWith(
                      color: isPositiveTrend != null
                          ? (isPositiveTrend!
                              ? LuluStatusColors.success
                              : LuluStatusColors.warning)
                          : LuluTextColors.tertiary,
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 수면 카드
class _SleepCard extends StatelessWidget {
  final double avgHours;
  final double trend;
  final S l10n;

  const _SleepCard({
    required this.avgHours,
    required this.trend,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = avgHours > 0;
    final value = hasData
        ? l10n.dailyGridHours(avgHours.toStringAsFixed(1))
        : l10n.dailyGridNoData;

    // 트렌드 텍스트
    String? trendText;
    bool? isPositive;
    if (hasData && trend.abs() > 0.1) {
      final trendHours = trend.abs().toStringAsFixed(1);
      trendText = trend > 0 ? '+$trendHours' : '-$trendHours';
      isPositive = trend > 0; // 수면 증가는 긍정적
    }

    return _CompactCard(
      accentColor: LuluPatternColors.nightSleep,
      icon: LuluIcons.sleep,
      label: l10n.dailyGridSleep,
      value: value,
      trendText: trendText,
      isPositiveTrend: isPositive,
    );
  }
}

/// 수유 카드
class _FeedingCard extends StatelessWidget {
  final int avgCount;
  final double avgGap;
  final double gapTrend;
  final S l10n;

  const _FeedingCard({
    required this.avgCount,
    required this.avgGap,
    required this.gapTrend,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = avgCount > 0;
    final value =
        hasData ? l10n.dailyGridCount(avgCount) : l10n.dailyGridNoData;

    // 간격 트렌드 텍스트
    String? trendText;
    bool? isPositive;
    if (hasData && avgGap > 0) {
      final gapStr = avgGap.toStringAsFixed(1);
      trendText = l10n.dailyGridGapInterval(gapStr);
      // 간격 증가는 긍정적 (더 오래 버팀)
      if (gapTrend.abs() > 0.1) {
        isPositive = gapTrend > 0;
      }
    }

    return _CompactCard(
      accentColor: LuluPatternColors.feeding,
      icon: LuluIcons.feeding,
      label: l10n.dailyGridFeeding,
      value: value,
      trendText: trendText,
      isPositiveTrend: isPositive,
    );
  }
}

/// 기저귀 카드
class _DiaperCard extends StatelessWidget {
  final double avgCount;
  final S l10n;

  const _DiaperCard({
    required this.avgCount,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = avgCount > 0;
    final value =
        hasData ? l10n.dailyGridCount(avgCount.round()) : l10n.dailyGridNoData;

    return _CompactCard(
      accentColor: LuluPatternColors.diaper,
      icon: LuluIcons.diaper,
      label: l10n.dailyGridDiaper,
      value: value,
    );
  }
}

/// 놀이 카드
class _PlayCard extends StatelessWidget {
  final double avgMinutes;
  final S l10n;

  const _PlayCard({
    required this.avgMinutes,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = avgMinutes > 0;
    final value = hasData
        ? l10n.dailyGridMinutes(avgMinutes.round())
        : l10n.dailyGridNoData;

    return _CompactCard(
      accentColor: LuluPatternColors.play,
      icon: LuluIcons.play,
      label: l10n.dailyGridPlay,
      value: value,
    );
  }
}
