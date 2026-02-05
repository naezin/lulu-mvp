import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/activity_model.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// 컨텍스트 리본 (일일 요약 한 줄)
///
/// Sprint 18-R Phase 4: 일일 요약을 한 줄 컴팩트하게
/// 형식: ●14.2h · ●7회 645ml · ●6회 · ●75분
class ContextRibbon extends StatelessWidget {
  const ContextRibbon({
    super.key,
    required this.activities,
  });

  final List<ActivityModel> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return const SizedBox.shrink();

    final l10n = S.of(context);
    final stats = _calculateStats();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: LuluColors.deepBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 수면 시간
            if (stats.sleepMinutes > 0) ...[
              _StatItem(
                color: LuluActivityColors.sleep,
                value: _formatDuration(stats.sleepMinutes),
              ),
              _Separator(),
            ],
            // 수유 횟수 + 총량
            if (stats.feedingCount > 0) ...[
              _StatItem(
                color: LuluActivityColors.feeding,
                value: stats.feedingMl > 0
                    ? '${stats.feedingCount}${l10n?.unitTimes ?? 'x'} ${stats.feedingMl}ml'
                    : '${stats.feedingCount}${l10n?.unitTimes ?? 'x'}',
              ),
              _Separator(),
            ],
            // 기저귀 횟수
            if (stats.diaperCount > 0) ...[
              _StatItem(
                color: LuluActivityColors.diaper,
                value: '${stats.diaperCount}${l10n?.unitTimes ?? 'x'}',
              ),
              _Separator(),
            ],
            // 놀이 시간
            if (stats.playMinutes > 0) ...[
              _StatItem(
                color: LuluActivityColors.play,
                value: _formatDuration(stats.playMinutes),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 통계 계산
  _DayStats _calculateStats() {
    int sleepMinutes = 0;
    int feedingCount = 0;
    int feedingMl = 0;
    int diaperCount = 0;
    int playMinutes = 0;

    for (final activity in activities) {
      switch (activity.type.name) {
        case 'sleep':
          if (activity.endTime != null) {
            sleepMinutes +=
                activity.endTime!.difference(activity.startTime).inMinutes;
          }
          break;
        case 'feeding':
          feedingCount++;
          final data = activity.data;
          if (data != null) {
            final amount = data['amount'];
            if (amount is num) {
              feedingMl += amount.toInt();
            }
          }
          break;
        case 'diaper':
          diaperCount++;
          break;
        case 'play':
          if (activity.endTime != null) {
            playMinutes +=
                activity.endTime!.difference(activity.startTime).inMinutes;
          }
          break;
      }
    }

    return _DayStats(
      sleepMinutes: sleepMinutes,
      feedingCount: feedingCount,
      feedingMl: feedingMl,
      diaperCount: diaperCount,
      playMinutes: playMinutes,
    );
  }

  /// 시간 포맷 (분 → 시간분)
  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h${mins}m';
  }
}

/// 일일 통계 데이터
class _DayStats {
  final int sleepMinutes;
  final int feedingCount;
  final int feedingMl;
  final int diaperCount;
  final int playMinutes;

  const _DayStats({
    required this.sleepMinutes,
    required this.feedingCount,
    required this.feedingMl,
    required this.diaperCount,
    required this.playMinutes,
  });
}

/// 통계 아이템
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.color,
    required this.value,
  });

  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: LuluTextStyles.bodySmall.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// 구분자
class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        '·',
        style: LuluTextStyles.bodyMedium.copyWith(
          color: LuluTextColors.tertiary,
        ),
      ),
    );
  }
}
