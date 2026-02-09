import 'package:flutter/foundation.dart';

/// 활동 타입 (패턴용)
enum PatternActivityType {
  nightSleep, // 밤잠 (21:00-06:00)
  daySleep, // 낮잠 (06:00-21:00)
  feeding, // 수유
  diaper, // 기저귀
  play, // 놀이 (v4.1 추가)
  health, // 건강 (v4.1 추가)
  empty, // 빈칸 (깨어있음)
}

/// 패턴 필터
enum PatternFilter { sleep, feeding, diaper, play, health, all }

/// 밤잠/낮잠 경계 시간 설정
class SleepTimeConfig {
  static const int nightStartHour = 21; // 밤잠 시작
  static const int nightEndHour = 6; // 밤잠 종료

  /// 해당 시간이 밤 시간인지 확인
  static bool isNightTime(int hour) {
    return hour >= nightStartHour || hour < nightEndHour;
  }
}

/// 30분 단위 시간 슬롯
@immutable
class TimeSlot {
  final int hour; // 0-23
  final int halfHour; // 0 또는 1
  final PatternActivityType activity;
  final String? activityId;
  final List<PatternActivityType> overlays; // v4.1 추가: 오버레이 활동

  const TimeSlot({
    required this.hour,
    required this.halfHour,
    required this.activity,
    this.activityId,
    this.overlays = const [], // v4.1 추가
  });

  int get slotIndex => hour * 2 + halfHour;

  String get timeString {
    final minute = halfHour == 0 ? '00' : '30';
    return '${hour.toString().padLeft(2, '0')}:$minute';
  }

  /// 특정 활동이 있는지 확인 (주 활동 + 오버레이 포함)
  bool hasActivity(PatternActivityType type) {
    return activity == type || overlays.contains(type);
  }

  TimeSlot copyWith({
    int? hour,
    int? halfHour,
    PatternActivityType? activity,
    String? activityId,
    List<PatternActivityType>? overlays,
  }) {
    return TimeSlot(
      hour: hour ?? this.hour,
      halfHour: halfHour ?? this.halfHour,
      activity: activity ?? this.activity,
      activityId: activityId ?? this.activityId,
      overlays: overlays ?? this.overlays,
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
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
  final String? correctedAge; // v4.1 추가: 교정연령 (예: "CA 5w3d")

  const WeeklyPattern({
    required this.days,
    required this.babyId,
    required this.babyName,
    this.correctedAge,
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
    String? correctedAge,
  }) {
    return WeeklyPattern(
      days: days ?? this.days,
      babyId: babyId ?? this.babyId,
      babyName: babyName ?? this.babyName,
      correctedAge: correctedAge ?? this.correctedAge,
    );
  }
}
