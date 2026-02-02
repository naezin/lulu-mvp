import 'package:flutter/material.dart';
import '../../core/design_system/lulu_colors.dart';
import '../../core/design_system/lulu_icons.dart';

/// 마지막 활동 Row 위젯
///
/// 작업 지시서 v1.2: TodaySummaryCard + LastActivityCard 통합
/// 3개의 활동 (수면, 수유, 기저귀)을 가로로 배치
class LastActivityRow extends StatelessWidget {
  /// 마지막 수면 시간 (null이면 "-" 표시)
  final DateTime? lastSleep;

  /// 마지막 수유 시간 (null이면 "-" 표시)
  final DateTime? lastFeeding;

  /// 마지막 기저귀 시간 (null이면 "-" 표시)
  final DateTime? lastDiaper;

  const LastActivityRow({
    super.key,
    this.lastSleep,
    this.lastFeeding,
    this.lastDiaper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LuluColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActivityItem(
              icon: LuluIcons.sleep,
              label: _formatTimeAgo(lastSleep),
              color: LuluActivityColors.sleep,
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _ActivityItem(
              icon: LuluIcons.feeding,
              label: _formatTimeAgo(lastFeeding),
              color: LuluActivityColors.feeding,
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _ActivityItem(
              icon: LuluIcons.diaper,
              label: _formatTimeAgo(lastDiaper),
              color: LuluActivityColors.diaper,
            ),
          ),
        ],
      ),
    );
  }

  /// 시간을 상대적 표현으로 변환
  String _formatTimeAgo(DateTime? time) {
    if (time == null) return '-';

    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '방금';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else {
      return '${diff.inDays}일 전';
    }
  }
}

/// 개별 활동 아이템
class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.label,
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
          style: TextStyle(
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
