import 'package:flutter/material.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_type.dart';

/// 24시간 미니 타임바 위젯
///
/// 작업 지시서 v1.1: 당일 패턴 시각화
/// - 수면: 밤잠(진한 보라) / 낮잠(연한 보라)
/// - 수유: 🍼 마커
/// - 현재 시간 마커 (오늘인 경우)
class MiniTimeBar extends StatelessWidget {
  final List<ActivityModel> activities;
  final DateTime date;
  final ValueChanged<int>? onHourTap;

  const MiniTimeBar({
    super.key,
    required this.activities,
    required this.date,
    this.onHourTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LuluColors.deepIndigo.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 시간 라벨
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [0, 3, 6, 9, 12, 15, 18, 21, 24].map((h) {
              return Text(
                h.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: LuluTextColors.tertiary,
                  fontSize: 9,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),

          // 타임바
          SizedBox(
            height: 24,
            child: Row(
              children: List.generate(48, (slotIndex) {
                return Expanded(
                  child: GestureDetector(
                    onTap:
                        onHourTap != null ? () => onHourTap!(slotIndex ~/ 2) : null,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      decoration: BoxDecoration(
                        color: _getSlotColor(slotIndex),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // 수유 마커
          SizedBox(
            height: 16,
            child: Row(
              children: List.generate(48, (slotIndex) {
                final hasFeeding = _hasFeedingInSlot(slotIndex);
                return Expanded(
                  child: hasFeeding
                      ? const Center(
                          child: Text(
                            '🍼',
                            style: TextStyle(fontSize: 8),
                          ),
                        )
                      : const SizedBox.shrink(),
                );
              }),
            ),
          ),

          // 현재 시간 마커 (오늘인 경우)
          if (_isToday) ...[
            const SizedBox(height: 4),
            _buildCurrentTimeMarker(),
          ],

          // 범례
          const SizedBox(height: 8),
          _buildLegend(),
        ],
      ),
    );
  }

  bool get _isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Color _getSlotColor(int slotIndex) {
    final slotStart = DateTime(
        date.year, date.month, date.day, slotIndex ~/ 2, (slotIndex % 2) * 30);
    final slotEnd = slotStart.add(const Duration(minutes: 30));

    for (final activity in activities) {
      if (activity.type != ActivityType.sleep) continue;

      final actEnd =
          activity.endTime ?? activity.startTime.add(const Duration(hours: 1));
      if (activity.startTime.isBefore(slotEnd) && actEnd.isAfter(slotStart)) {
        final hour = slotIndex ~/ 2;
        return (hour >= 21 || hour < 6)
            ? LuluPatternColors.nightSleep
            : LuluPatternColors.daySleep;
      }
    }
    return Colors.transparent;
  }

  bool _hasFeedingInSlot(int slotIndex) {
    final slotStart = DateTime(
        date.year, date.month, date.day, slotIndex ~/ 2, (slotIndex % 2) * 30);
    final slotEnd = slotStart.add(const Duration(minutes: 30));

    return activities.any((a) =>
        a.type == ActivityType.feeding &&
        a.startTime
            .isAfter(slotStart.subtract(const Duration(minutes: 1))) &&
        a.startTime.isBefore(slotEnd));
  }

  Widget _buildCurrentTimeMarker() {
    final now = DateTime.now();
    final position = (now.hour * 2 + now.minute ~/ 30) / 48;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned(
              left: constraints.maxWidth * position - 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: LuluPatternColors.currentTimeMarker,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(LuluPatternColors.nightSleep, '밤잠'),
        const SizedBox(width: 12),
        _legendItem(LuluPatternColors.daySleep, '낮잠'),
        const SizedBox(width: 12),
        const Text('🍼', style: TextStyle(fontSize: 10)),
        const SizedBox(width: 4),
        Text(
          '수유',
          style: TextStyle(
            color: LuluTextColors.secondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: LuluTextColors.secondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
