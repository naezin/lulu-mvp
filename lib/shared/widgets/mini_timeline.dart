import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design_system/lulu_colors.dart';
import '../../core/design_system/lulu_spacing.dart';
import '../../core/design_system/lulu_typography.dart';
import '../../data/models/activity_model.dart';
import '../../data/models/baby_type.dart';

/// 최근 활동 미니 타임라인 (Sprint 6 Day 2)
///
/// F-3 컴팩트 레이아웃: 최근 5개 활동 표시 (스크롤 없음)
class MiniTimeline extends StatelessWidget {
  /// 최근 활동 목록 (최대 5개)
  final List<ActivityModel> activities;

  /// 전체 타임라인 보기 콜백
  final VoidCallback? onViewAllTap;

  const MiniTimeline({
    super.key,
    required this.activities,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    // 최대 5개만 표시
    final displayActivities = activities.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(LuluSpacing.lg),
      decoration: BoxDecoration(
        color: LuluColors.deepBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: LuluColors.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '최근 기록',
                style: LuluTextStyles.labelMedium.copyWith(
                  color: LuluTextColors.secondary,
                ),
              ),
              if (onViewAllTap != null && activities.length > 5)
                GestureDetector(
                  onTap: onViewAllTap,
                  child: Text(
                    '전체 보기',
                    style: LuluTextStyles.caption.copyWith(
                      color: LuluColors.lavenderMist,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: LuluSpacing.md),

          // 활동 없음
          if (displayActivities.isEmpty)
            _buildEmptyState()
          else
            // 활동 목록
            ...displayActivities.map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: LuluSpacing.sm),
                child: _TimelineItem(activity: activity),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LuluSpacing.lg),
      child: Center(
        child: Column(
          children: [
            Text(
              '📝',
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: LuluSpacing.sm),
            Text(
              '오늘 기록이 없어요',
              style: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 타임라인 개별 아이템
class _TimelineItem extends StatelessWidget {
  final ActivityModel activity;

  const _TimelineItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final emoji = _getEmoji();
    final color = _getColor();
    final title = _getTitle();
    final detail = _getDetail();
    final time = DateFormat('HH:mm').format(activity.startTime);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.md,
        vertical: LuluSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: LuluColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 시간
          SizedBox(
            width: 48,
            child: Text(
              time,
              style: LuluTextStyles.labelMedium.copyWith(
                color: LuluTextColors.secondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          // 아이콘
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: LuluSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          // 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: LuluTextStyles.bodySmall.copyWith(
                    color: LuluTextColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    style: LuluTextStyles.caption.copyWith(
                      color: LuluTextColors.tertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // 진행 중 표시
          if (activity.isOngoing)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: LuluSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '진행 중',
                style: LuluTextStyles.caption.copyWith(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getEmoji() {
    return switch (activity.type) {
      ActivityType.feeding => '🍼',
      ActivityType.sleep => '😴',
      ActivityType.diaper => '🧷',
      ActivityType.play => '🎮',
      ActivityType.health => '🏥',
    };
  }

  Color _getColor() {
    return switch (activity.type) {
      ActivityType.feeding => LuluActivityColors.feeding,
      ActivityType.sleep => LuluActivityColors.sleep,
      ActivityType.diaper => LuluActivityColors.diaper,
      ActivityType.play => LuluActivityColors.play,
      ActivityType.health => LuluActivityColors.health,
    };
  }

  String _getTitle() {
    return switch (activity.type) {
      ActivityType.feeding => '수유',
      ActivityType.sleep => activity.isOngoing ? '수면 시작' : '수면 종료',
      ActivityType.diaper => '기저귀',
      ActivityType.play => '놀이',
      ActivityType.health => '건강',
    };
  }

  String _getDetail() {
    final data = activity.data;
    if (data == null) return '';

    switch (activity.type) {
      case ActivityType.feeding:
        final feedingType = data['feeding_type'] as String?;
        final amount = data['amount_ml'] as num?;
        final duration = data['duration_minutes'] as int?;

        final typeStr = switch (feedingType) {
          'breast' => '모유',
          'bottle' => '젖병',
          'formula' => '분유',
          'solid' => '이유식',
          _ => '',
        };

        if (amount != null && amount > 0) {
          return '$typeStr ${amount.toInt()}ml';
        }
        if (duration != null && duration > 0) {
          return '$typeStr $duration분';
        }
        return typeStr;

      case ActivityType.sleep:
        if (activity.endTime != null) {
          final duration = activity.endTime!.difference(activity.startTime);
          final hours = duration.inHours;
          final mins = duration.inMinutes % 60;
          if (hours > 0 && mins > 0) return '$hours시간 $mins분';
          if (hours > 0) return '$hours시간';
          return '$mins분';
        }
        return '';

      case ActivityType.diaper:
        final diaperType = data['diaper_type'] as String?;
        final stoolColor = data['stool_color'] as String?;

        final typeStr = switch (diaperType) {
          'wet' => '소변',
          'dirty' => '대변',
          'both' => '혼합',
          'dry' => '건조',
          _ => '',
        };

        if (stoolColor != null) {
          final colorStr = switch (stoolColor) {
            'yellow' => '노랑',
            'brown' => '갈색',
            'green' => '녹색',
            'black' => '검정',
            'red' => '빨강',
            'white' => '흰색',
            _ => '',
          };
          return '$typeStr ($colorStr)';
        }
        return typeStr;

      case ActivityType.play:
        final playType = data['play_type'] as String?;
        return switch (playType) {
          'tummy_time' => '터미타임',
          'bath' => '목욕',
          'outdoor' => '외출',
          'play' => '실내놀이',
          'reading' => '독서',
          _ => '',
        };

      case ActivityType.health:
        final temp = data['temperature'] as num?;
        if (temp != null) {
          return '체온 ${temp.toStringAsFixed(1)}°C';
        }
        final healthType = data['health_type'] as String?;
        return switch (healthType) {
          'temperature' => '체온 측정',
          'symptom' => '증상 기록',
          'medication' => '투약 기록',
          'hospital' => '병원 방문',
          _ => '',
        };
    }
  }
}
