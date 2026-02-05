import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// 경과 시간 표시 위젯
///
/// Sprint 18-R Phase 5: 활동 시작 후 경과 시간을 실시간으로 표시
/// 예: "2시간 30분 전" or "30분 전"
class ElapsedTimeIndicator extends StatefulWidget {
  const ElapsedTimeIndicator({
    super.key,
    required this.startTime,
    this.showIcon = true,
    this.compact = false,
  });

  /// 활동 시작 시간
  final DateTime startTime;

  /// 아이콘 표시 여부
  final bool showIcon;

  /// 컴팩트 모드 (작은 텍스트)
  final bool compact;

  @override
  State<ElapsedTimeIndicator> createState() => _ElapsedTimeIndicatorState();
}

class _ElapsedTimeIndicatorState extends State<ElapsedTimeIndicator> {
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
    final l10n = S.of(context);
    final elapsed = DateTime.now().difference(widget.startTime);
    final text = _formatElapsed(elapsed, l10n);

    if (widget.compact) {
      return Text(
        text,
        style: LuluTextStyles.bodySmall.copyWith(
          color: LuluTextColors.tertiary,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIcon) ...[
          Icon(
            Icons.schedule_rounded,
            size: 14,
            color: LuluTextColors.tertiary,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          style: LuluTextStyles.bodySmall.copyWith(
            color: LuluTextColors.tertiary,
          ),
        ),
      ],
    );
  }

  /// 경과 시간 포맷
  String _formatElapsed(Duration elapsed, S? l10n) {
    final minutes = elapsed.inMinutes;
    final hours = elapsed.inHours;
    final days = elapsed.inDays;

    if (days > 0) {
      return l10n?.elapsedDaysAgo(days) ?? '${days}d ago';
    } else if (hours > 0) {
      final remainingMinutes = minutes % 60;
      if (remainingMinutes > 0) {
        return l10n?.elapsedHoursMinutesAgo(hours, remainingMinutes) ??
            '${hours}h ${remainingMinutes}m ago';
      }
      return l10n?.elapsedHoursAgo(hours) ?? '${hours}h ago';
    } else if (minutes > 0) {
      return l10n?.elapsedMinutesAgo(minutes) ?? '${minutes}m ago';
    } else {
      return l10n?.elapsedJustNow ?? 'Just now';
    }
  }
}
