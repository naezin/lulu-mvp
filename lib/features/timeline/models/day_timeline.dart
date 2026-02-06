import 'package:flutter/foundation.dart';

/// Duration 활동 블록 (수면, 놀이)
/// 실제 시간 기반 - 30분 슬롯 아님
@immutable
class DurationBlock {
  final String type; // 'nightSleep', 'daySleep', 'play'
  final DateTime startTime;
  final DateTime endTime;
  final String? activityId;

  const DurationBlock({
    required this.type,
    required this.startTime,
    required this.endTime,
    this.activityId,
  });

  /// 시작 시간 (시간 단위, 소수점 포함)
  double get startHour =>
      startTime.toLocal().hour + startTime.toLocal().minute / 60.0;

  /// 종료 시간 (시간 단위, 소수점 포함)
  double get endHour =>
      endTime.toLocal().hour + endTime.toLocal().minute / 60.0;

  /// 지속 시간 (시간 단위)
  double get durationHours {
    final diff = endTime.difference(startTime);
    return diff.inMinutes / 60.0;
  }

  /// 지속 시간 (분 단위)
  int get durationMinutes => endTime.difference(startTime).inMinutes;

  DurationBlock copyWith({
    String? type,
    DateTime? startTime,
    DateTime? endTime,
    String? activityId,
  }) {
    return DurationBlock(
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      activityId: activityId ?? this.activityId,
    );
  }
}

/// Instant 활동 마커 (수유, 기저귀, 건강)
/// 특정 시점의 활동
@immutable
class InstantMarker {
  final String type; // 'feeding', 'diaper', 'health'
  final DateTime time;
  final Map<String, dynamic>? data; // amount, method 등
  final String? activityId;

  const InstantMarker({
    required this.type,
    required this.time,
    this.data,
    this.activityId,
  });

  /// 시간 (시간 단위, 소수점 포함)
  double get timeHour => time.toLocal().hour + time.toLocal().minute / 60.0;

  InstantMarker copyWith({
    String? type,
    DateTime? time,
    Map<String, dynamic>? data,
    String? activityId,
  }) {
    return InstantMarker(
      type: type ?? this.type,
      time: time ?? this.time,
      data: data ?? this.data,
      activityId: activityId ?? this.activityId,
    );
  }
}

/// 하루 타임라인 (실제 시간 기반)
/// DailyGrid, WeeklyChartFull용
@immutable
class DayTimeline {
  final DateTime date;
  final List<DurationBlock> durationBlocks;
  final List<InstantMarker> instantMarkers;

  const DayTimeline({
    required this.date,
    required this.durationBlocks,
    required this.instantMarkers,
  });

  factory DayTimeline.empty(DateTime date) {
    return DayTimeline(
      date: date,
      durationBlocks: const [],
      instantMarkers: const [],
    );
  }

  /// 총 수면 시간 (시간 단위)
  double get totalSleepHours => durationBlocks
      .where((b) => b.type == 'nightSleep' || b.type == 'daySleep')
      .fold(0.0, (sum, b) => sum + b.durationHours);

  /// 총 수면 시간 (분 단위)
  int get totalSleepMinutes => durationBlocks
      .where((b) => b.type == 'nightSleep' || b.type == 'daySleep')
      .fold(0, (sum, b) => sum + b.durationMinutes);

  /// 수유 횟수
  int get feedingCount =>
      instantMarkers.where((m) => m.type == 'feeding').length;

  /// 평균 수유 간격 (시간 단위)
  double get avgFeedingGap {
    final feedings = instantMarkers
        .where((m) => m.type == 'feeding')
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    if (feedings.length < 2) return 0;

    double totalGap = 0;
    for (int i = 1; i < feedings.length; i++) {
      final gap = feedings[i].time.difference(feedings[i - 1].time);
      totalGap += gap.inMinutes / 60.0;
    }
    return totalGap / (feedings.length - 1);
  }

  /// 기저귀 횟수
  int get diaperCount =>
      instantMarkers.where((m) => m.type == 'diaper').length;

  /// 놀이 시간 (분 단위)
  int get playMinutes => durationBlocks
      .where((b) => b.type == 'play')
      .fold(0, (sum, b) => sum + b.durationMinutes);

  /// 마지막 수면 종료 시간
  DateTime? get lastSleepEnd {
    final sleeps = durationBlocks
        .where((b) => b.type == 'nightSleep' || b.type == 'daySleep')
        .toList()
      ..sort((a, b) => b.endTime.compareTo(a.endTime));
    return sleeps.isNotEmpty ? sleeps.first.endTime : null;
  }

  /// 마지막 수유 시간
  DateTime? get lastFeedingTime {
    final feedings = instantMarkers
        .where((m) => m.type == 'feeding')
        .toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    return feedings.isNotEmpty ? feedings.first.time : null;
  }

  /// 마지막 기저귀 시간
  DateTime? get lastDiaperTime {
    final diapers = instantMarkers
        .where((m) => m.type == 'diaper')
        .toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    return diapers.isNotEmpty ? diapers.first.time : null;
  }

  /// 데이터 존재 여부
  bool get hasData => durationBlocks.isNotEmpty || instantMarkers.isNotEmpty;

  /// 요일 문자열
  String get weekdayString {
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday];
  }

  /// 날짜 문자열
  String get dateString => '${date.month}/${date.day}';

  DayTimeline copyWith({
    DateTime? date,
    List<DurationBlock>? durationBlocks,
    List<InstantMarker>? instantMarkers,
  }) {
    return DayTimeline(
      date: date ?? this.date,
      durationBlocks: durationBlocks ?? this.durationBlocks,
      instantMarkers: instantMarkers ?? this.instantMarkers,
    );
  }
}

/// 주간 요약 (트렌드 포함)
@immutable
class WeeklySummary {
  final double avgSleepHours; // 일 평균 수면
  final double avgFeedGap; // 평균 수유 간격
  final int avgFeedCount; // 일 평균 수유 횟수
  final double avgDiapers; // 일 평균 기저귀
  final double avgPlayMinutes; // 일 평균 놀이

  // 트렌드 (주 초 대비 주 말 변화량)
  final double sleepTrend; // 양수면 증가, 음수면 감소
  final double feedGapTrend; // 양수면 간격 넓어짐

  // 밤잠 시작 시간 평균 (WeeklyInsight용)
  final double? avgNightSleepStartHour;

  const WeeklySummary({
    required this.avgSleepHours,
    required this.avgFeedGap,
    required this.avgFeedCount,
    required this.avgDiapers,
    required this.avgPlayMinutes,
    required this.sleepTrend,
    required this.feedGapTrend,
    this.avgNightSleepStartHour,
  });

  factory WeeklySummary.empty() {
    return const WeeklySummary(
      avgSleepHours: 0,
      avgFeedGap: 0,
      avgFeedCount: 0,
      avgDiapers: 0,
      avgPlayMinutes: 0,
      sleepTrend: 0,
      feedGapTrend: 0,
    );
  }

  /// 수면 트렌드 방향 (up, down, stable)
  String get sleepTrendDirection {
    if (sleepTrend > 0.3) return 'up';
    if (sleepTrend < -0.3) return 'down';
    return 'stable';
  }

  /// 수유 간격 트렌드 방향
  String get feedGapTrendDirection {
    if (feedGapTrend > 0.3) return 'up';
    if (feedGapTrend < -0.3) return 'down';
    return 'stable';
  }
}
