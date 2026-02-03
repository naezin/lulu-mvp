/// 권장 범위 상태
enum RecommendationStatus {
  inRange,
  belowRange,
  aboveRange,
  unknown,
}

/// 권장 범위 결과
class RecommendationResult {
  final RecommendationStatus status;
  final double? min;
  final double? max;

  const RecommendationResult({
    required this.status,
    this.min,
    this.max,
  });

  static const unknown = RecommendationResult(
    status: RecommendationStatus.unknown,
  );
}

/// 권장 범위 유틸리티
///
/// 교정 연령 기반 수면/수유/기저귀 권장 범위
/// 출처: WHO, AAP 가이드라인 참고 (참고용, 의료 조언 아님)
class RecommendationRanges {
  RecommendationRanges._();

  /// 수면 권장 범위 확인
  static RecommendationResult checkSleep({
    required int correctedAgeDays,
    required double hoursPerDay,
  }) {
    final range = _getSleepRange(correctedAgeDays);
    if (range == null) return RecommendationResult.unknown;

    if (hoursPerDay < range.$1) {
      return RecommendationResult(
        status: RecommendationStatus.belowRange,
        min: range.$1,
        max: range.$2,
      );
    } else if (hoursPerDay > range.$2) {
      return RecommendationResult(
        status: RecommendationStatus.aboveRange,
        min: range.$1,
        max: range.$2,
      );
    } else {
      return RecommendationResult(
        status: RecommendationStatus.inRange,
        min: range.$1,
        max: range.$2,
      );
    }
  }

  /// 수유 권장 범위 확인
  static RecommendationResult checkFeeding({
    required int correctedAgeDays,
    required double timesPerDay,
  }) {
    final range = _getFeedingRange(correctedAgeDays);
    if (range == null) return RecommendationResult.unknown;

    if (timesPerDay < range.$1) {
      return RecommendationResult(
        status: RecommendationStatus.belowRange,
        min: range.$1,
        max: range.$2,
      );
    } else if (timesPerDay > range.$2) {
      return RecommendationResult(
        status: RecommendationStatus.aboveRange,
        min: range.$1,
        max: range.$2,
      );
    } else {
      return RecommendationResult(
        status: RecommendationStatus.inRange,
        min: range.$1,
        max: range.$2,
      );
    }
  }

  /// 기저귀 권장 범위 확인
  static RecommendationResult checkDiaper({
    required int correctedAgeDays,
    required double timesPerDay,
  }) {
    final range = _getDiaperRange(correctedAgeDays);
    if (range == null) return RecommendationResult.unknown;

    if (timesPerDay < range.$1) {
      return RecommendationResult(
        status: RecommendationStatus.belowRange,
        min: range.$1,
        max: range.$2,
      );
    } else if (timesPerDay > range.$2) {
      return RecommendationResult(
        status: RecommendationStatus.aboveRange,
        min: range.$1,
        max: range.$2,
      );
    } else {
      return RecommendationResult(
        status: RecommendationStatus.inRange,
        min: range.$1,
        max: range.$2,
      );
    }
  }

  /// 수면 권장 범위 (시간/일)
  /// 출처: WHO Sleep Guidelines (참고용)
  static (double, double)? _getSleepRange(int correctedAgeDays) {
    if (correctedAgeDays < 0) return null;

    final months = correctedAgeDays / 30;

    if (months < 1) {
      return (14.0, 17.0); // 신생아: 14-17시간
    } else if (months < 4) {
      return (14.0, 17.0); // 1-3개월: 14-17시간
    } else if (months < 12) {
      return (12.0, 16.0); // 4-11개월: 12-16시간
    } else if (months < 24) {
      return (11.0, 14.0); // 1-2세: 11-14시간
    } else {
      return (10.0, 13.0); // 2세+: 10-13시간
    }
  }

  /// 수유 권장 범위 (회/일)
  /// 출처: AAP Feeding Guidelines (참고용)
  static (double, double)? _getFeedingRange(int correctedAgeDays) {
    if (correctedAgeDays < 0) return null;

    final months = correctedAgeDays / 30;

    if (months < 1) {
      return (8.0, 12.0); // 신생아: 8-12회
    } else if (months < 4) {
      return (6.0, 10.0); // 1-3개월: 6-10회
    } else if (months < 6) {
      return (5.0, 8.0); // 4-5개월: 5-8회
    } else if (months < 12) {
      return (4.0, 6.0); // 6-11개월: 4-6회 (이유식 포함)
    } else {
      return (3.0, 5.0); // 12개월+: 3-5회
    }
  }

  /// 기저귀 권장 범위 (회/일)
  /// 출처: Pediatric Guidelines (참고용)
  static (double, double)? _getDiaperRange(int correctedAgeDays) {
    if (correctedAgeDays < 0) return null;

    final months = correctedAgeDays / 30;

    if (months < 1) {
      return (8.0, 12.0); // 신생아: 8-12회
    } else if (months < 3) {
      return (6.0, 10.0); // 1-2개월: 6-10회
    } else if (months < 6) {
      return (5.0, 8.0); // 3-5개월: 5-8회
    } else if (months < 12) {
      return (4.0, 7.0); // 6-11개월: 4-7회
    } else {
      return (4.0, 6.0); // 12개월+: 4-6회
    }
  }
}
