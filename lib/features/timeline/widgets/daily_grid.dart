import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../models/day_timeline.dart';

/// DailyGrid - 일간 요약 2x2 그리드
///
/// Sprint 19: MiniTimeBar + ContextRibbon + LastActivityBadges 대체
/// - 수면: 총 시간 + 마지막 수면 경과
/// - 수유: 횟수 + 간격 + 마지막 수유 경과
/// - 기저귀: 횟수 + 마지막 기저귀 경과
/// - 놀이: 총 시간
class DailyGrid extends StatelessWidget {
  final DayTimeline dayTimeline;
  final DateTime selectedDate;

  const DailyGrid({
    super.key,
    required this.dayTimeline,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.md,
        vertical: LuluSpacing.sm,
      ),
      child: Column(
        children: [
          // Row 1: Sleep + Feeding
          Row(
            children: [
              Expanded(
                child: _SleepCard(
                  dayTimeline: dayTimeline,
                  isToday: isToday,
                  l10n: l10n,
                ),
              ),
              const SizedBox(width: LuluSpacing.sm),
              Expanded(
                child: _FeedingCard(
                  dayTimeline: dayTimeline,
                  isToday: isToday,
                  l10n: l10n,
                ),
              ),
            ],
          ),
          const SizedBox(height: LuluSpacing.sm),
          // Row 2: Diaper + Play
          Row(
            children: [
              Expanded(
                child: _DiaperCard(
                  dayTimeline: dayTimeline,
                  isToday: isToday,
                  l10n: l10n,
                ),
              ),
              const SizedBox(width: LuluSpacing.sm),
              Expanded(
                child: _PlayCard(
                  dayTimeline: dayTimeline,
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

/// 기본 카드 위젯
class _GridCard extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final String? elapsed;

  const _GridCard({
    required this.accentColor,
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    this.elapsed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.md),
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: accentColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Label
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: accentColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: LuluTextStyles.labelSmall.copyWith(
                  color: LuluTextColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: LuluSpacing.xs),

          // Value
          Text(
            value,
            style: LuluTextStyles.titleMedium.copyWith(
              color: LuluTextColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Sub value (optional)
          if (subValue != null) ...[
            const SizedBox(height: 2),
            Text(
              subValue!,
              style: LuluTextStyles.labelSmall.copyWith(
                color: LuluTextColors.tertiary,
              ),
            ),
          ],

          // Elapsed time (optional)
          if (elapsed != null) ...[
            const SizedBox(height: LuluSpacing.xs),
            Text(
              elapsed!,
              style: LuluTextStyles.labelSmall.copyWith(
                color: accentColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 수면 카드
class _SleepCard extends StatelessWidget {
  final DayTimeline dayTimeline;
  final bool isToday;
  final S l10n;

  const _SleepCard({
    required this.dayTimeline,
    required this.isToday,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final totalHours = dayTimeline.totalSleepHours;
    final hasData = totalHours > 0;

    // Value formatting
    final hours = totalHours.toStringAsFixed(1);
    final value = hasData ? l10n.dailyGridHours(hours) : l10n.dailyGridNoData;

    // Elapsed time (only for today)
    String? elapsed;
    if (isToday && hasData && dayTimeline.lastSleepEnd != null) {
      elapsed = _formatElapsed(dayTimeline.lastSleepEnd!, l10n);
    }

    return _GridCard(
      accentColor: LuluPatternColors.nightSleep,
      icon: LuluIcons.sleep,
      label: l10n.dailyGridSleep,
      value: value,
      elapsed: elapsed,
    );
  }
}

/// 수유 카드
class _FeedingCard extends StatelessWidget {
  final DayTimeline dayTimeline;
  final bool isToday;
  final S l10n;

  const _FeedingCard({
    required this.dayTimeline,
    required this.isToday,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final count = dayTimeline.feedingCount;
    final hasData = count > 0;

    // Value formatting
    final value = hasData ? l10n.dailyGridCount(count) : l10n.dailyGridNoData;

    // Sub value: average gap
    String? subValue;
    if (count >= 2) {
      final gap = dayTimeline.avgFeedingGap.toStringAsFixed(1);
      subValue = l10n.dailyGridGapInterval(gap);
    }

    // Elapsed time (only for today)
    String? elapsed;
    if (isToday && hasData && dayTimeline.lastFeedingTime != null) {
      elapsed = _formatElapsed(dayTimeline.lastFeedingTime!, l10n);
    }

    return _GridCard(
      accentColor: LuluPatternColors.feeding,
      icon: LuluIcons.feeding,
      label: l10n.dailyGridFeeding,
      value: value,
      subValue: subValue,
      elapsed: elapsed,
    );
  }
}

/// 기저귀 카드
class _DiaperCard extends StatelessWidget {
  final DayTimeline dayTimeline;
  final bool isToday;
  final S l10n;

  const _DiaperCard({
    required this.dayTimeline,
    required this.isToday,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final count = dayTimeline.diaperCount;
    final hasData = count > 0;

    // Value formatting
    final value = hasData ? l10n.dailyGridCount(count) : l10n.dailyGridNoData;

    // Elapsed time (only for today)
    String? elapsed;
    if (isToday && hasData && dayTimeline.lastDiaperTime != null) {
      elapsed = _formatElapsed(dayTimeline.lastDiaperTime!, l10n);
    }

    return _GridCard(
      accentColor: LuluPatternColors.diaper,
      icon: LuluIcons.diaper,
      label: l10n.dailyGridDiaper,
      value: value,
      elapsed: elapsed,
    );
  }
}

/// 놀이 카드
class _PlayCard extends StatelessWidget {
  final DayTimeline dayTimeline;
  final S l10n;

  const _PlayCard({
    required this.dayTimeline,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = dayTimeline.playMinutes;
    final hasData = minutes > 0;

    // Value formatting
    final value = hasData ? l10n.dailyGridMinutes(minutes) : l10n.dailyGridNoData;

    return _GridCard(
      accentColor: LuluPatternColors.play,
      icon: LuluIcons.play,
      label: l10n.dailyGridPlay,
      value: value,
    );
  }
}

/// 경과 시간 포맷팅
String _formatElapsed(DateTime time, S l10n) {
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inMinutes < 60) {
    return l10n.dailyGridElapsedMinutes(diff.inMinutes);
  } else {
    return l10n.dailyGridElapsedHours(diff.inHours);
  }
}
