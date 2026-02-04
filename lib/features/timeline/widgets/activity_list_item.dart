import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_type.dart';

/// 스와이프 가능한 활동 리스트 아이템
///
/// 작업 지시서 v1.1: flutter_slidable 사용
/// - 왼쪽 스와이프 → 수정/삭제 버튼
/// - 첫 사용 시 스와이프 힌트 표시
class ActivityListItem extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final bool showSwipeHint;

  const ActivityListItem({
    super.key,
    required this.activity,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
    this.showSwipeHint = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Slidable(
        key: Key(activity.id),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.4,
          children: [
            CustomSlidableAction(
              onPressed: (_) {
                HapticFeedback.mediumImpact();
                onEdit();
              },
              backgroundColor: LuluPatternColors.editAction,
              foregroundColor: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.edit_rounded, size: 20),
                  SizedBox(height: 2),
                  Text(
                    '수정',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            CustomSlidableAction(
              onPressed: (_) {
                HapticFeedback.heavyImpact();
                onDelete();
              },
              backgroundColor: LuluPatternColors.deleteAction,
              foregroundColor: Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.delete_rounded, size: 20),
                  SizedBox(height: 2),
                  Text(
                    '삭제',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LuluColors.deepIndigo.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildIcon(),
                    const SizedBox(width: 16),
                    Expanded(child: _buildContent()),
                    Icon(
                      Icons.chevron_left_rounded,
                      color: LuluTextColors.tertiary.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ],
                ),
              ),
              // 첫 사용 시 스와이프 힌트
              if (showSwipeHint)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: LuluColors.lavenderMist,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.swipe_left_rounded,
                              size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            '밀어서 수정/삭제',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;
    switch (activity.type) {
      case ActivityType.feeding:
        icon = LuluIcons.feeding;
        color = LuluActivityColors.feeding;
      case ActivityType.sleep:
        icon = LuluIcons.sleep;
        color = LuluActivityColors.sleep;
      case ActivityType.diaper:
        icon = LuluIcons.diaper;
        color = LuluActivityColors.diaper;
      case ActivityType.play:
        icon = LuluIcons.play;
        color = LuluActivityColors.play;
      case ActivityType.health:
        icon = LuluIcons.health;
        color = LuluActivityColors.health;
    }
    return Icon(icon, size: 24, color: color);
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _formatTime(activity.startTime),
              style: const TextStyle(
                color: LuluTextColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (activity.endTime != null) ...[
              Text(
                '-${_formatTime(activity.endTime!)}',
                style: TextStyle(
                  color: LuluTextColors.secondary,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _buildSummary(),
                style: const TextStyle(
                  color: LuluTextColors.primary,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (activity.notes != null && activity.notes!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            activity.notes!,
            style: TextStyle(
              color: LuluTextColors.secondary,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _buildSummary() {
    switch (activity.type) {
      case ActivityType.feeding:
        final amount = activity.data?['amount_ml'] as num?;
        final feedType = activity.data?['feeding_type'] as String? ?? '수유';
        final displayType = _getFeedingTypeDisplay(feedType);
        return amount != null ? '$displayType ${amount.toInt()}ml' : displayType;
      case ActivityType.sleep:
        if (activity.endTime != null) {
          final duration = activity.endTime!.difference(activity.startTime);
          final hours = duration.inHours;
          final minutes = duration.inMinutes % 60;
          return hours > 0 ? '수면 $hours시간 $minutes분' : '수면 $minutes분';
        }
        return '수면 중';
      case ActivityType.diaper:
        final diaperType = activity.data?['diaper_type'] as String? ?? 'diaper';
        final diaperDisplay = _getDiaperTypeDisplay(diaperType);
        return '기저귀 ($diaperDisplay)';
      case ActivityType.play:
        final playType = activity.data?['play_type'] as String? ?? '놀이';
        return playType;
      case ActivityType.health:
        final temp = activity.data?['temperature'] as num?;
        if (temp != null) {
          return '체온 ${temp.toStringAsFixed(1)}°C';
        }
        return '건강 기록';
    }
  }

  String _getFeedingTypeDisplay(String type) {
    switch (type.toLowerCase()) {
      case 'breast':
      case 'breast_milk':
        return '모유';
      case 'formula':
        return '분유';
      case 'bottle':
        return '젖병';
      case 'solid':
        return '이유식';
      default:
        return '수유';
    }
  }

  String _getDiaperTypeDisplay(String type) {
    switch (type.toLowerCase()) {
      case 'wet':
        return '소변';
      case 'dirty':
        return '대변';
      case 'both':
        return '소변+대변';
      case 'dry':
        return '건조';
      default:
        return type;
    }
  }
}
