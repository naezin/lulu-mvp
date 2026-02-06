import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_type.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// HF5: 마지막 활동 경과 시간 배지
///
/// 수면/수유/기저귀 각각의 마지막 기록으로부터 경과 시간을 표시
/// 예: [수면 4h 52m 전] [수유 2h 23m 전] [기저귀 1h 08m 전]
class LastActivityBadges extends StatefulWidget {
  const LastActivityBadges({
    super.key,
    required this.activities,
  });

  final List<ActivityModel> activities;

  @override
  State<LastActivityBadges> createState() => _LastActivityBadgesState();
}

class _LastActivityBadgesState extends State<LastActivityBadges> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 1분마다 업데이트
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lastSleep = _getLastActivity(ActivityType.sleep);
    final lastFeeding = _getLastActivity(ActivityType.feeding);
    final lastDiaper = _getLastActivity(ActivityType.diaper);

    // 활동이 하나도 없으면 표시 안 함
    if (lastSleep == null && lastFeeding == null && lastDiaper == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: LuluSpacing.md),
      padding: const EdgeInsets.symmetric(vertical: LuluSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (lastSleep != null) ...[
              _ActivityBadge(
                icon: LuluIcons.sleep,
                color: LuluActivityColors.sleep,
                startTime: lastSleep.endTime ?? lastSleep.startTime,
              ),
              const SizedBox(width: LuluSpacing.sm),
            ],
            if (lastFeeding != null) ...[
              _ActivityBadge(
                icon: LuluIcons.feeding,
                color: LuluActivityColors.feeding,
                startTime: lastFeeding.startTime,
              ),
              const SizedBox(width: LuluSpacing.sm),
            ],
            if (lastDiaper != null) ...[
              _ActivityBadge(
                icon: LuluIcons.diaper,
                color: LuluActivityColors.diaper,
                startTime: lastDiaper.startTime,
              ),
            ],
          ],
        ),
      ),
    );
  }

  ActivityModel? _getLastActivity(ActivityType type) {
    final filtered = widget.activities
        .where((a) => a.type == type)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return filtered.isNotEmpty ? filtered.first : null;
  }
}

/// 개별 활동 배지
class _ActivityBadge extends StatelessWidget {
  const _ActivityBadge({
    required this.icon,
    required this.color,
    required this.startTime,
  });

  final IconData icon;
  final Color color;
  final DateTime startTime;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final elapsed = DateTime.now().difference(startTime);
    final text = _formatElapsed(elapsed, l10n);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.sm,
        vertical: LuluSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatElapsed(Duration elapsed, S? l10n) {
    final minutes = elapsed.inMinutes;
    final hours = elapsed.inHours;
    final days = elapsed.inDays;

    if (days > 0) {
      return l10n?.elapsedDaysAgo(days) ?? '${days}d';
    } else if (hours > 0) {
      final remainingMinutes = minutes % 60;
      if (remainingMinutes > 0) {
        return l10n?.elapsedHoursMinutesAgo(hours, remainingMinutes) ??
            '${hours}h ${remainingMinutes}m';
      }
      return l10n?.elapsedHoursAgo(hours) ?? '${hours}h';
    } else if (minutes > 0) {
      return l10n?.elapsedMinutesAgo(minutes) ?? '${minutes}m';
    } else {
      return l10n?.elapsedJustNow ?? 'Now';
    }
  }
}
