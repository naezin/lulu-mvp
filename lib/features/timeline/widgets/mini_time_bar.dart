import 'package:flutter/material.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_type.dart';

/// 24시간 미니 타임바 위젯
///
/// HF2 v2 재작성: 5종 활동 모두 컬러바로 표시
/// - 수면(밤잠/낮잠), 수유, 기저귀, 놀이, 건강 모두 색상 막대
/// - 아이콘 완전 제거
/// - 범례 제거 (FilterChips가 역할 대체)
/// - 48슬롯 (30분 단위) 24시간 표시
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
          // 시간 라벨 (0~24시)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [0, 6, 12, 18, 24].map((h) {
              return Text(
                h.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: LuluTextColors.tertiary,
                  fontSize: 10,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),

          // 타임바 - 48슬롯 (5종 활동 모두 컬러바)
          SizedBox(
            height: 24,
            child: Row(
              children: List.generate(48, (slotIndex) {
                return Expanded(
                  child: GestureDetector(
                    onTap: onHourTap != null ? () => onHourTap!(slotIndex ~/ 2) : null,
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

          // 현재 시간 마커 (오늘인 경우)
          if (_isToday) ...[
            const SizedBox(height: 4),
            _buildCurrentTimeMarker(),
          ],

          // HF2-4: 범례 제거 (FilterChips가 역할 대체)
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

  /// HF8-FIX: Duration 활동 클램핑 + Instant 활동 1분 폭
  /// 우선순위: 수면 > 수유 > 기저귀 > 놀이 > 건강
  Color _getSlotColor(int slotIndex) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final slotStart = DateTime(
        date.year, date.month, date.day, slotIndex ~/ 2, (slotIndex % 2) * 30);
    final slotEnd = slotStart.add(const Duration(minutes: 30));

    Color? sleepColor;
    Color? feedingColor;
    Color? diaperColor;
    Color? playColor;
    Color? healthColor;

    for (final activity in activities) {
      final actStart = activity.startTime.toLocal();

      // HF8-FIX: Duration vs Instant 활동 분리 처리
      bool overlapsSlot = false;

      if (activity.endTime != null) {
        // Duration 활동: 해당 날짜 범위로 클램핑 후 슬롯 비교
        final actEnd = activity.endTime!.toLocal();
        final clampedStart = actStart.isBefore(dayStart) ? dayStart : actStart;
        final clampedEnd = actEnd.isAfter(dayEnd) ? dayEnd : actEnd;
        overlapsSlot = clampedStart.isBefore(slotEnd) && clampedEnd.isAfter(slotStart);
      } else {
        // Instant 활동: 1분 폭으로 슬롯 비교
        final actEnd = actStart.add(const Duration(minutes: 1));
        overlapsSlot = actStart.isBefore(slotEnd) && actEnd.isAfter(slotStart);
      }

      if (overlapsSlot) {
        switch (activity.type) {
          case ActivityType.sleep:
            final sleepType = activity.data?['sleep_type'] as String?;
            if (sleepType == 'night') {
              sleepColor = LuluPatternColors.nightSleep;
            } else if (sleepType == 'nap') {
              sleepColor = LuluPatternColors.daySleep;
            } else {
              final hour = slotIndex ~/ 2;
              sleepColor = (hour >= 21 || hour < 6)
                  ? LuluPatternColors.nightSleep
                  : LuluPatternColors.daySleep;
            }
          case ActivityType.feeding:
            feedingColor = LuluPatternColors.feeding;
          case ActivityType.diaper:
            diaperColor = LuluPatternColors.diaper;
          case ActivityType.play:
            playColor = LuluPatternColors.play;
          case ActivityType.health:
            healthColor = LuluPatternColors.health;
        }
      }
    }

    // 우선순위: 수면 > 수유 > 기저귀 > 놀이 > 건강
    return sleepColor ?? feedingColor ?? diaperColor ?? playColor ?? healthColor ?? Colors.transparent;
  }

  Widget _buildCurrentTimeMarker() {
    final now = DateTime.now();
    final position = (now.hour * 2 + now.minute ~/ 30) / 48;
    return SizedBox(
      height: 8,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: constraints.maxWidth * position - 4,
                top: 0,
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
      ),
    );
  }
}
