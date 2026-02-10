import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_type.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

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
    final l10n = S.of(context);

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
            // Sprint 20 HF #12 + U2: 아이콘만 표시 (텍스트 제거 → overflow 방지)
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
              child: const Icon(LuluIcons.edit, size: 22),
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
              child: const Icon(LuluIcons.delete, size: 22),
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
                  color: LuluColors.deepIndigoMedium,
                  borderRadius: BorderRadius.circular(LuluRadius.sm),
                ),
                child: Row(
                  children: [
                    _buildIcon(),
                    const SizedBox(width: 16),
                    Expanded(child: _buildContent(l10n)),
                    Icon(
                      LuluIcons.chevronLeft,
                      color: LuluTextColors.tertiaryMedium,
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
                        borderRadius: BorderRadius.circular(LuluRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LuluIcons.chevronLeft,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            l10n?.swipeHint ?? 'Swipe to edit/delete',
                            style: const TextStyle(
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

  Widget _buildContent(S? l10n) {
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
                _buildSummary(l10n),
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

  String _buildSummary(S? l10n) {
    switch (activity.type) {
      case ActivityType.feeding:
        final amount = activity.data?['amount_ml'] as num?;
        final feedType = activity.data?['feeding_type'] as String? ?? 'feeding';
        final displayType = _getFeedingTypeDisplay(feedType, l10n);
        return amount != null ? '$displayType ${amount.toInt()}ml' : displayType;
      case ActivityType.sleep:
        if (activity.endTime != null) {
          final duration = activity.endTime!.difference(activity.startTime);
          final hours = duration.inHours;
          final minutes = duration.inMinutes % 60;
          final sleepLabel = l10n?.activityTypeSleep ?? 'Sleep';
          if (hours > 0) {
            return l10n?.durationHoursMinutes(hours, minutes) ?? '$sleepLabel ${hours}h ${minutes}m';
          }
          return l10n?.durationMinutes(minutes) ?? '$sleepLabel ${minutes}m';
        }
        return l10n?.statusOngoing ?? 'Sleeping';
      case ActivityType.diaper:
        final diaperType = activity.data?['diaper_type'] as String? ?? 'diaper';
        final diaperDisplay = _getDiaperTypeDisplay(diaperType, l10n);
        final diaperLabel = l10n?.activityTypeDiaper ?? 'Diaper';
        return '$diaperLabel ($diaperDisplay)';
      case ActivityType.play:
        final playType = activity.data?['play_type'] as String?;
        return _getPlayTypeDisplay(playType, l10n);
      case ActivityType.health:
        final temp = activity.data?['temperature'] as num?;
        if (temp != null) {
          final tempLabel = l10n?.temperature ?? 'Temp';
          return '$tempLabel ${temp.toStringAsFixed(1)}C';
        }
        return l10n?.activityTypeHealth ?? 'Health';
    }
  }

  String _getFeedingTypeDisplay(String type, S? l10n) {
    switch (type.toLowerCase()) {
      case 'breast':
      case 'breast_milk':
        return l10n?.feedingTypeBreast ?? 'Breast';
      case 'formula':
        return l10n?.feedingTypeFormula ?? 'Formula';
      case 'bottle':
        return l10n?.feedingTypeBottle ?? 'Bottle';
      case 'solid':
        return l10n?.feedingTypeSolid ?? 'Solid';
      default:
        return l10n?.activityTypeFeeding ?? 'Feeding';
    }
  }

  String _getDiaperTypeDisplay(String type, S? l10n) {
    switch (type.toLowerCase()) {
      case 'wet':
        return l10n?.diaperTypeWet ?? 'Wet';
      case 'dirty':
        return l10n?.diaperTypeDirty ?? 'Dirty';
      case 'both':
        return l10n?.diaperTypeBothDetail ?? 'Both';
      case 'dry':
        return l10n?.diaperTypeDry ?? 'Dry';
      default:
        return type;
    }
  }

  String _getPlayTypeDisplay(String? type, S? l10n) {
    if (type == null) return l10n?.activityTypePlay ?? 'Play';
    switch (type.toLowerCase()) {
      case 'tummy_time':
        return l10n?.playTypeTummyTime ?? 'Tummy Time';
      case 'bath':
        return l10n?.playTypeBath ?? 'Bath';
      case 'outdoor':
        return l10n?.playTypeOutdoor ?? 'Outdoor';
      case 'indoor':
        return l10n?.playTypeIndoor ?? 'Indoor';
      case 'reading':
        return l10n?.playTypeReading ?? 'Reading';
      default:
        return l10n?.playTypeOther ?? 'Other';
    }
  }
}
