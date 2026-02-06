import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../models/day_timeline.dart';

/// WeeklyInsight - 주간 트렌드 한줄 요약
///
/// Sprint 19: 주간 뷰 재설계
/// - 수면/수유 트렌드 기반 인사이트
/// - 밤잠 시작 시간 패턴
class WeeklyInsight extends StatelessWidget {
  final WeeklySummary weeklySummary;

  const WeeklyInsight({
    super.key,
    required this.weeklySummary,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;
    final insight = _generateInsight(l10n);

    if (insight == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.md,
        vertical: LuluSpacing.sm,
      ),
      padding: const EdgeInsets.all(LuluSpacing.md),
      decoration: BoxDecoration(
        color: insight.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: insight.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            insight.icon,
            color: insight.color,
            size: 20,
          ),
          const SizedBox(width: LuluSpacing.sm),
          Expanded(
            child: Text(
              insight.message,
              style: LuluTextStyles.bodySmall.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 인사이트 생성
  _InsightData? _generateInsight(S l10n) {
    // 데이터 없음
    if (weeklySummary.avgSleepHours == 0 && weeklySummary.avgFeedCount == 0) {
      return null;
    }

    // 1. 수면 트렌드 인사이트
    if (weeklySummary.sleepTrend.abs() > 0.3) {
      if (weeklySummary.sleepTrend > 0) {
        return _InsightData(
          message: l10n.weeklyInsightSleepIncrease,
          icon: Icons.bedtime_rounded,
          color: LuluStatusColors.success,
        );
      } else {
        return _InsightData(
          message: l10n.weeklyInsightSleepDecrease,
          icon: Icons.bedtime_outlined,
          color: LuluStatusColors.warning,
        );
      }
    }

    // 2. 수유 간격 트렌드 인사이트
    if (weeklySummary.feedGapTrend.abs() > 0.2) {
      if (weeklySummary.feedGapTrend > 0) {
        return _InsightData(
          message: l10n.weeklyInsightFeedGapIncrease,
          icon: Icons.access_time_rounded,
          color: LuluStatusColors.success,
        );
      } else {
        return _InsightData(
          message: l10n.weeklyInsightFeedGapDecrease,
          icon: Icons.access_time_outlined,
          color: LuluStatusColors.warning,
        );
      }
    }

    // 3. 밤잠 시작 시간 인사이트
    if (weeklySummary.avgNightSleepStartHour != null) {
      final hour = weeklySummary.avgNightSleepStartHour!;
      final hourStr = hour.toStringAsFixed(0);
      final minStr = ((hour - hour.floor()) * 60).round().toString().padLeft(2, '0');
      return _InsightData(
        message: l10n.weeklyInsightNightSleepStart('$hourStr:$minStr'),
        icon: Icons.nights_stay_rounded,
        color: LuluColors.lavenderMist,
      );
    }

    // 4. 기본 중립 메시지
    return _InsightData(
      message: l10n.weeklyInsightStable,
      icon: Icons.check_circle_outline_rounded,
      color: LuluColors.lavenderMist,
    );
  }
}

/// 인사이트 데이터
class _InsightData {
  final String message;
  final IconData icon;
  final Color color;

  const _InsightData({
    required this.message,
    required this.icon,
    required this.color,
  });
}
