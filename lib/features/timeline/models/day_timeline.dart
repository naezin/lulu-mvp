import 'package:flutter/foundation.dart';

/// Duration 기반 활동 블록 (수면, 수유, 놀이)
///
/// Sprint 19: 30분 슬롯 → 실시간 duration 기반 렌더링 지원
@immutable
class DurationBlock {
  final String type; // 'sleep', 'feeding', 'play'
  final DateTime startTime;
  final DateTime endTime;
  final String? subType; // 'night_sleep', 'day_sleep', 'breast', 'bottle', 'formula'
  final String? activityId;

  const DurationBlock({
    required this.type,
    required this.startTime,
    required this.endTime,
    this.subType,
    this.activityId,
  });

  Duration get duration => endTime.difference(startTime);

  /// 하루 경계 [dayStart, dayEnd)로 클램핑
  DurationBlock clampToDay(DateTime dayStart, DateTime dayEnd) {
    return DurationBlock(
      type: type,
      startTime: startTime.isBefore(dayStart) ? dayStart : startTime,
      endTime: endTime.isAfter(dayEnd) ? dayEnd : endTime,
      subType: subType,
      activityId: activityId,
    );
  }

  DurationBlock copyWith({
    String? type,
    DateTime? startTime,
    DateTime? endTime,
    String? subType,
    String? activityId,
  }) {
    return DurationBlock(
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subType: subType ?? this.subType,
      activityId: activityId ?? this.activityId,
    );
  }
}

/// 즉시 이벤트 마커 (기저귀, 건강)
@immutable
class InstantMarker {
  final String type; // 'diaper', 'health'
  final DateTime time;
  final Map<String, dynamic>? data;
  final String? activityId;

  const InstantMarker({
    required this.type,
    required this.time,
    this.data,
    this.activityId,
  });

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

/// 하루 전체 타임라인
///
/// Sprint 19 v5: 모든 활동을 allBlocks로 통합 (세로 스택 렌더링용)
/// Duration 블록 + Instant 마커 → 전부 DurationBlock으로 변환
@immutable
class DayTimeline {
  final DateTime date;

  /// 모든 활동 (렌더링용) - Instant도 DurationBlock으로 변환됨
  final List<DurationBlock> allBlocks;

  /// 레거시: Duration 기반 활동만
  final List<DurationBlock> durationBlocks;

  /// 레거시: Instant 마커 (통계 계산용)
  final List<InstantMarker> instantMarkers;

  const DayTimeline({
    required this.date,
    required this.allBlocks,
    required this.durationBlocks,
    required this.instantMarkers,
  });

  /// 빈 타임라인 생성
  factory DayTimeline.empty(DateTime date) {
    return DayTimeline(
      date: date,
      allBlocks: const [],
      durationBlocks: const [],
      instantMarkers: const [],
    );
  }

  /// 특정 타입의 총 duration
  Duration totalDuration(String type, {String? subType}) {
    return durationBlocks
        .where((b) => b.type == type && (subType == null || b.subType == subType))
        .fold(Duration.zero, (sum, b) => sum + b.duration);
  }

  /// 특정 타입의 instant 개수
  int countInstant(String type) =>
      instantMarkers.where((m) => m.type == type).length;

  /// 특정 타입의 duration 블록 개수
  int countDuration(String type) =>
      durationBlocks.where((b) => b.type == type).length;

  /// 특정 타입의 마지막 활동 시간
  DateTime? lastActivityTime(String type) {
    final times = <DateTime>[];

    for (final b in durationBlocks.where((b) => b.type == type)) {
      times.add(b.endTime);
    }
    for (final m in instantMarkers.where((m) => m.type == type)) {
      times.add(m.time);
    }

    if (times.isEmpty) return null;
    times.sort();
    return times.last;
  }

  /// 데이터가 있는지 확인
  bool get hasData => allBlocks.isNotEmpty || durationBlocks.isNotEmpty || instantMarkers.isNotEmpty;

  // ============================================================
  // Wake Window (깨시) segment calculation — C-0.6
  // ============================================================

  /// Wake segments: gaps between consecutive sleep blocks
  ///
  /// Returns list of Duration representing each awake period.
  /// Filters: skip negative/zero gaps (overlapping records),
  ///          skip 10h+ gaps (overnight = not meaningful wake segment)
  List<Duration> get wakeSegments {
    final sleepBlocks = durationBlocks
        .where((b) => b.type == 'sleep')
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (sleepBlocks.length < 2) return [];

    final segments = <Duration>[];
    for (int i = 0; i < sleepBlocks.length - 1; i++) {
      final wakeStart = sleepBlocks[i].endTime;
      final wakeEnd = sleepBlocks[i + 1].startTime;
      final duration = wakeEnd.difference(wakeStart);

      if (duration.inMinutes > 0 && duration.inHours < 10) {
        segments.add(duration);
      }
    }
    return segments;
  }

  /// Average wake segment duration in minutes (null if no segments)
  double? get wakeSegmentAverageMinutes {
    final segs = wakeSegments;
    if (segs.isEmpty) return null;
    final totalMinutes = segs.fold(0, (sum, d) => sum + d.inMinutes);
    return totalMinutes / segs.length;
  }

  /// Number of wake segments
  int get wakeSegmentCount => wakeSegments.length;

  DayTimeline copyWith({
    DateTime? date,
    List<DurationBlock>? allBlocks,
    List<DurationBlock>? durationBlocks,
    List<InstantMarker>? instantMarkers,
  }) {
    return DayTimeline(
      date: date ?? this.date,
      allBlocks: allBlocks ?? this.allBlocks,
      durationBlocks: durationBlocks ?? this.durationBlocks,
      instantMarkers: instantMarkers ?? this.instantMarkers,
    );
  }
}

/// 주간 요약
///
/// Sprint 19 v4: Map → 개별 필드 (타입 안전성)
@immutable
class WeeklySummary {
  /// 평균 수면 시간 (시간)
  final double avgSleepHours;
  /// 수면 트렌드 (전주 대비, 양수=증가)
  final double sleepTrend;

  /// 평균 수유 횟수
  final double avgFeedingCount;
  /// 수유 횟수 트렌드
  final double feedingCountTrend;

  /// 평균 수유량 (ml)
  final double avgFeedingMl;
  /// 수유량 트렌드
  final double feedingMlTrend;

  /// 평균 기저귀 횟수
  final double avgDiaperCount;
  /// 기저귀 트렌드
  final double diaperTrend;

  /// 평균 놀이 시간 (분)
  final double avgPlayMinutes;
  /// 놀이 트렌드
  final double playTrend;

  /// 평균 깨시 구간 (분) — C-0.6
  final double avgWakeSegmentMinutes;
  /// 깨시 구간 트렌드
  final double wakeSegmentTrend;

  const WeeklySummary({
    required this.avgSleepHours,
    this.sleepTrend = 0,
    required this.avgFeedingCount,
    this.feedingCountTrend = 0,
    this.avgFeedingMl = 0,
    this.feedingMlTrend = 0,
    required this.avgDiaperCount,
    this.diaperTrend = 0,
    required this.avgPlayMinutes,
    this.playTrend = 0,
    this.avgWakeSegmentMinutes = 0,
    this.wakeSegmentTrend = 0,
  });

  /// 빈 요약
  factory WeeklySummary.empty() {
    return const WeeklySummary(
      avgSleepHours: 0,
      sleepTrend: 0,
      avgFeedingCount: 0,
      feedingCountTrend: 0,
      avgFeedingMl: 0,
      feedingMlTrend: 0,
      avgDiaperCount: 0,
      diaperTrend: 0,
      avgPlayMinutes: 0,
      playTrend: 0,
      avgWakeSegmentMinutes: 0,
      wakeSegmentTrend: 0,
    );
  }

  WeeklySummary copyWith({
    double? avgSleepHours,
    double? sleepTrend,
    double? avgFeedingCount,
    double? feedingCountTrend,
    double? avgFeedingMl,
    double? feedingMlTrend,
    double? avgDiaperCount,
    double? diaperTrend,
    double? avgPlayMinutes,
    double? playTrend,
    double? avgWakeSegmentMinutes,
    double? wakeSegmentTrend,
  }) {
    return WeeklySummary(
      avgSleepHours: avgSleepHours ?? this.avgSleepHours,
      sleepTrend: sleepTrend ?? this.sleepTrend,
      avgFeedingCount: avgFeedingCount ?? this.avgFeedingCount,
      feedingCountTrend: feedingCountTrend ?? this.feedingCountTrend,
      avgFeedingMl: avgFeedingMl ?? this.avgFeedingMl,
      feedingMlTrend: feedingMlTrend ?? this.feedingMlTrend,
      avgDiaperCount: avgDiaperCount ?? this.avgDiaperCount,
      diaperTrend: diaperTrend ?? this.diaperTrend,
      avgPlayMinutes: avgPlayMinutes ?? this.avgPlayMinutes,
      playTrend: playTrend ?? this.playTrend,
      avgWakeSegmentMinutes: avgWakeSegmentMinutes ?? this.avgWakeSegmentMinutes,
      wakeSegmentTrend: wakeSegmentTrend ?? this.wakeSegmentTrend,
    );
  }
}
