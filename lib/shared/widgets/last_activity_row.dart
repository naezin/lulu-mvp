import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/design_system/lulu_colors.dart';
import '../../core/design_system/lulu_radius.dart';
import '../../core/design_system/lulu_icons.dart';
import '../../l10n/generated/app_localizations.dart' show S;

/// B-2 LastActivityRow: 수유/기저귀 마지막 활동 경과 시간 표시
///
/// Sprint 26: 수면 항목 제거 (SweetSpotCard 깨시로 완전 대체)
/// - 2칸 구조: 수유 + 기저귀
/// - Timer: 1분마다 경과 시간 자동 갱신
/// - i18n: ARB 키 기반 (하드코딩 한글 0)
class LastActivityRow extends StatefulWidget {
  /// 마지막 수유 시간 (null이면 "-" 표시)
  final DateTime? lastFeeding;

  /// 마지막 기저귀 시간 (null이면 "-" 표시)
  final DateTime? lastDiaper;

  const LastActivityRow({
    super.key,
    this.lastFeeding,
    this.lastDiaper,
  });

  @override
  State<LastActivityRow> createState() => _LastActivityRowState();
}

class _LastActivityRowState extends State<LastActivityRow> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
        border: Border.all(color: LuluColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActivityItem(
              icon: LuluIcons.feeding,
              label: l10n?.lastActivityFeeding ?? 'Feeding',
              timeText: _formatTimeAgo(l10n, widget.lastFeeding),
              color: LuluActivityColors.feeding,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _ActivityItem(
              icon: LuluIcons.diaper,
              label: l10n?.lastActivityDiaper ?? 'Diaper',
              timeText: _formatTimeAgo(l10n, widget.lastDiaper),
              color: LuluActivityColors.diaper,
            ),
          ),
        ],
      ),
    );
  }

  /// 경과 시간을 i18n 기반 상대 표현으로 변환
  String _formatTimeAgo(S? l10n, DateTime? time) {
    if (time == null) return l10n?.lastActivityNoRecord ?? '-';

    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return l10n?.timeAgoJustNow ?? 'Just now';
    } else if (diff.inMinutes < 60) {
      return l10n?.timeAgoMinutes(diff.inMinutes) ?? '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      final remainingMinutes = diff.inMinutes % 60;
      return l10n?.timeAgoHoursMinutes(diff.inHours, remainingMinutes) ??
          '${diff.inHours}h ${remainingMinutes}m ago';
    } else {
      return l10n?.daysAgoCount(diff.inDays) ?? '${diff.inDays}d ago';
    }
  }
}

/// 개별 활동 아이템 (아이콘 + 라벨 + 경과 시간)
class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String timeText;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.label,
    required this.timeText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 24,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: LuluTextColors.tertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          timeText,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: LuluTextColors.primary,
          ),
        ),
      ],
    );
  }
}

/// 세로 구분선
class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: LuluColors.glassBorder,
    );
  }
}
