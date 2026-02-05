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

  /// HF2-1,2,4: 5종 활동 모두 컬러바로 표시
  /// 우선순위: 수면 > 수유 > 기저귀 > 놀이 > 건강
  Color _getSlotColor(int slotIndex) {
    final slotStart = DateTime(
        date.year, date.month, date.day, slotIndex ~/ 2, (slotIndex % 2) * 30);
    final slotEnd = slotStart.add(const Duration(minutes: 30));

    // 우선순위별로 활동 확인
    Color? sleepColor;
    Color? feedingColor;
    Color? diaperColor;
    Color? playColor;
    Color? healthColor;

    for (final activity in activities) {
      // UTC -> Local 변환
      final actStart = activity.startTime.toLocal();
      final actEnd = (activity.endTime ?? activity.startTime.add(const Duration(hours: 1))).toLocal();

      // 슬롯과 겹치는지 확인
      if (actStart.isBefore(slotEnd) && actEnd.isAfter(slotStart)) {
        switch (activity.type) {
          case ActivityType.sleep:
            final hour = slotIndex ~/ 2;
            sleepColor = (hour >= 21 || hour < 6)
                ? LuluPatternColors.nightSleep
                : LuluPatternColors.daySleep;
          case ActivityType.feeding:
            feedingColor = LuluPatternColors.feeding;
          case ActivityType.diaper:
            diaperColor = LuluActivityColors.diaper;
          case ActivityType.play:
            playColor = LuluActivityColors.play;
          case ActivityType.health:
            healthColor = LuluActivityColors.health;
        }
      }
    }

    // 우선순위: 수면 > 수유 > 기저귀 > 놀이 > 건강
    return sleepColor ?? feedingColor ?? diaperColor ?? playColor ?? healthColor ?? Colors.transparent;
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
}
