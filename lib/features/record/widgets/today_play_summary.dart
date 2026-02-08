import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_type.dart';

/// PL-03: 오늘 놀이 기록 요약 위젯
///
/// 기록 화면 상단에 오늘의 놀이 통계를 표시
/// - 총 놀이 시간
/// - 터미타임 횟수/시간
/// - 목욕/외출 여부
class TodayPlaySummary extends StatelessWidget {
  /// 오늘의 놀이 기록 목록
  final List<ActivityModel> todayActivities;

  /// 현재 선택된 아기 이름
  final String? babyName;

  const TodayPlaySummary({
    super.key,
    required this.todayActivities,
    this.babyName,
  });

  @override
  Widget build(BuildContext context) {
    final playActivities = todayActivities
        .where((a) => a.type == ActivityType.play)
        .toList();

    if (playActivities.isEmpty) {
      return const SizedBox.shrink();
    }

    final stats = _calculateStats(playActivities);

    return Container(
      margin: const EdgeInsets.only(bottom: LuluSpacing.lg),
      padding: const EdgeInsets.all(LuluSpacing.md),
      decoration: BoxDecoration(
        color: LuluActivityColors.playBg,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(LuluIcons.play, size: 16, color: LuluActivityColors.play),
              const SizedBox(width: LuluSpacing.xs),
              Text(
                babyName != null ? '$babyName 오늘의 놀이' : '오늘의 놀이',
                style: LuluTextStyles.labelMedium.copyWith(
                  color: LuluActivityColors.play,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: LuluSpacing.sm),

          // 통계 표시
          Wrap(
            spacing: LuluSpacing.md,
            runSpacing: LuluSpacing.xs,
            children: [
              // 총 놀이 시간
              _StatChip(
                label: '총 ${stats.totalMinutes}분',
                color: LuluActivityColors.play,
              ),

              // 터미타임
              if (stats.tummyTimeCount > 0)
                _StatChip(
                  label: '터미타임 ${stats.tummyTimeCount}회 (${stats.tummyTimeMinutes}분)',
                  color: LuluStatusColors.success,
                ),

              // 목욕
              if (stats.hasBath)
                _StatChip(
                  label: '목욕 완료',
                  icon: LuluIcons.checkCircleOutline,
                  color: LuluStatusColors.info,
                ),

              // 외출
              if (stats.hasOutdoor)
                _StatChip(
                  label: '외출',
                  icon: LuluIcons.checkCircleOutline,
                  color: LuluStatusColors.info,
                ),
            ],
          ),
        ],
      ),
    );
  }

  _PlayStats _calculateStats(List<ActivityModel> activities) {
    int totalMinutes = 0;
    int tummyTimeCount = 0;
    int tummyTimeMinutes = 0;
    bool hasBath = false;
    bool hasOutdoor = false;

    for (final activity in activities) {
      final data = activity.data;
      if (data == null) continue;

      final duration = data['duration_minutes'] as int? ?? 0;
      final playType = data['play_type'] as String?;

      totalMinutes += duration;

      switch (playType) {
        case 'tummy_time':
          tummyTimeCount++;
          tummyTimeMinutes += duration;
          break;
        case 'bath':
          hasBath = true;
          break;
        case 'outdoor':
          hasOutdoor = true;
          break;
      }
    }

    return _PlayStats(
      totalMinutes: totalMinutes,
      tummyTimeCount: tummyTimeCount,
      tummyTimeMinutes: tummyTimeMinutes,
      hasBath: hasBath,
      hasOutdoor: hasOutdoor,
    );
  }
}

class _PlayStats {
  final int totalMinutes;
  final int tummyTimeCount;
  final int tummyTimeMinutes;
  final bool hasBath;
  final bool hasOutdoor;

  const _PlayStats({
    required this.totalMinutes,
    required this.tummyTimeCount,
    required this.tummyTimeMinutes,
    required this.hasBath,
    required this.hasOutdoor,
  });
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const _StatChip({
    required this.label,
    this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.sm,
        vertical: LuluSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(LuluRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: LuluTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
