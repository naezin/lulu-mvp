import 'package:flutter/foundation.dart';

/// 활동 타입 (패턴용)
enum PatternActivityType {
  nightSleep, // 밤잠 (21:00-06:00)
  daySleep, // 낮잠 (06:00-21:00)
  feeding, // 수유
  diaper, // 기저귀
  empty, // 빈칸
}

/// 패턴 필터
enum PatternFilter { sleep, feeding, all }

/// 30분 단위 시간 슬롯
@immutable
class TimeSlot {
  final int hour; // 0-23
  final int halfHour; // 0 또는 1
  final PatternActivityType activity;
  final String? activityId;

  const TimeSlot({
    required this.hour,
    required this.halfHour,
    required this.activity,
    this.activityId,
  });

  int get slotIndex => hour * 2 + halfHour;

  String get timeString {
    final minute = halfHour == 0 ? '00' : '30';
    return '${hour.toString().padLeft(2, '0')}:$minute';
  }

  TimeSlot copyWith({
    int? hour,
    int? halfHour,
    PatternActivityType? activity,
    String? activityId,
  }) {
    return TimeSlot(
      hour: hour ?? this.hour,
      halfHour: halfHour ?? this.halfHour,
      activity: activity ?? this.activity,
      activityId: activityId ?? this.activityId,
    );
  }
}

/// 하루 패턴
@immutable
class DailyPattern {
  final DateTime date;
  final List<TimeSlot> slots; // 48개

  const DailyPattern({required this.date, required this.slots});

  factory DailyPattern.empty(DateTime date) {
    return DailyPattern(
      date: date,
      slots: List.generate(
        48,
        (i) => TimeSlot(
          hour: i ~/ 2,
          halfHour: i % 2,
          activity: PatternActivityType.empty,
        ),
      ),
    );
  }

  String get weekdayString {
    const days = ['', '월', '화', '수', '목', '금', '토', '일'];
    return days[date.weekday];
  }

  String get dateString => '${date.month}/${date.day}';

  bool get hasData =>
      slots.any((s) => s.activity != PatternActivityType.empty);

  DailyPattern copyWith({
    DateTime? date,
    List<TimeSlot>? slots,
  }) {
    return DailyPattern(
      date: date ?? this.date,
      slots: slots ?? this.slots,
    );
  }
}

/// 주간 패턴
@immutable
class WeeklyPattern {
  final List<DailyPattern> days; // 7일
  final String babyId;
  final String babyName;

  const WeeklyPattern({
    required this.days,
    required this.babyId,
    required this.babyName,
  });

  factory WeeklyPattern.empty(String babyId, String babyName) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return WeeklyPattern(
      days: List.generate(
        7,
        (i) => DailyPattern.empty(startOfWeek.add(Duration(days: i))),
      ),
      babyId: babyId,
      babyName: babyName,
    );
  }

  int get daysWithData => days.where((d) => d.hasData).length;
  bool get hasEnoughData => daysWithData >= 3;

  WeeklyPattern copyWith({
    List<DailyPattern>? days,
    String? babyId,
    String? babyName,
  }) {
    return WeeklyPattern(
      days: days ?? this.days,
      babyId: babyId ?? this.babyId,
      babyName: babyName ?? this.babyName,
    );
  }
}
