/// 주간 통계 데이터 모델
///
/// 작업 지시서 v1.2.1: 통계 화면용 데이터 모델
class WeeklyStatistics {
  /// 수면 통계
  final SleepStatistics sleep;

  /// 수유 통계
  final FeedingStatistics feeding;

  /// 기저귀 통계
  final DiaperStatistics diaper;

  /// 놀이 통계
  final PlayStatistics? play;

  /// 울음 통계
  final CryingStatistics? crying;

  /// 통계 기간 시작일
  final DateTime startDate;

  /// 통계 기간 종료일
  final DateTime endDate;

  const WeeklyStatistics({
    required this.sleep,
    required this.feeding,
    required this.diaper,
    this.play,
    this.crying,
    required this.startDate,
    required this.endDate,
  });

  /// 빈 통계 생성
  factory WeeklyStatistics.empty() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return WeeklyStatistics(
      sleep: SleepStatistics.empty(),
      feeding: FeedingStatistics.empty(),
      diaper: DiaperStatistics.empty(),
      play: PlayStatistics.empty(),
      crying: null,
      startDate: weekAgo,
      endDate: now,
    );
  }
}

/// 수면 통계
class SleepStatistics {
  /// 일 평균 수면 시간 (시간 단위)
  final double dailyAverageHours;

  /// 지난주 대비 변화 (분 단위, 양수=증가, 음수=감소)
  final int changeMinutes;

  /// 요일별 수면 시간 (월~일, 시간 단위)
  final List<double> dailyHours;

  /// 낮잠 비율 (0.0 ~ 1.0)
  final double napRatio;

  /// 밤잠 비율 (0.0 ~ 1.0)
  final double nightRatio;

  /// 야간 기상 횟수
  final int nightWakeups;

  const SleepStatistics({
    required this.dailyAverageHours,
    required this.changeMinutes,
    required this.dailyHours,
    required this.napRatio,
    required this.nightRatio,
    required this.nightWakeups,
  });

  factory SleepStatistics.empty() {
    return const SleepStatistics(
      dailyAverageHours: 0,
      changeMinutes: 0,
      dailyHours: [0, 0, 0, 0, 0, 0, 0],
      napRatio: 0,
      nightRatio: 0,
      nightWakeups: 0,
    );
  }

  /// 변화 유형 반환
  ChangeType get changeType {
    if (changeMinutes > 0) return ChangeType.increase;
    if (changeMinutes < 0) return ChangeType.decrease;
    return ChangeType.neutral;
  }
}

/// 수유 통계
class FeedingStatistics {
  /// 일 평균 수유 횟수
  final double dailyAverageCount;

  /// 🔧 Sprint 19 E: 일 평균 수유량 (ml)
  final double dailyAverageMl;

  /// 지난주 대비 변화 (횟수, 양수=증가, 음수=감소)
  final int changeCount;

  /// 🔧 Sprint 19 v4: 지난주 대비 수유량 변화 (ml, 양수=증가, 음수=감소)
  final int changeMl;

  /// 요일별 수유 횟수 (월~일)
  final List<int> dailyCounts;

  /// 모유 비율 (0.0 ~ 1.0)
  final double breastMilkRatio;

  /// 분유 비율 (0.0 ~ 1.0)
  final double formulaRatio;

  /// 이유식 비율 (0.0 ~ 1.0)
  final double solidFoodRatio;

  const FeedingStatistics({
    required this.dailyAverageCount,
    this.dailyAverageMl = 0,
    required this.changeCount,
    this.changeMl = 0,
    required this.dailyCounts,
    required this.breastMilkRatio,
    required this.formulaRatio,
    required this.solidFoodRatio,
  });

  factory FeedingStatistics.empty() {
    return const FeedingStatistics(
      dailyAverageCount: 0,
      dailyAverageMl: 0,
      changeCount: 0,
      changeMl: 0,
      dailyCounts: [0, 0, 0, 0, 0, 0, 0],
      breastMilkRatio: 0,
      formulaRatio: 0,
      solidFoodRatio: 0,
    );
  }

  /// 변화 유형 반환
  ChangeType get changeType {
    if (changeCount > 0) return ChangeType.increase;
    if (changeCount < 0) return ChangeType.decrease;
    return ChangeType.neutral;
  }
}

/// 기저귀 통계
class DiaperStatistics {
  /// 일 평균 기저귀 교체 횟수
  final double dailyAverageCount;

  /// 지난주 대비 변화 (횟수, 양수=증가, 음수=감소)
  final int changeCount;

  /// 요일별 기저귀 교체 횟수 (월~일)
  final List<int> dailyCounts;

  /// 소변 비율 (0.0 ~ 1.0)
  final double wetRatio;

  /// 대변 비율 (0.0 ~ 1.0)
  final double dirtyRatio;

  /// 혼합 비율 (0.0 ~ 1.0)
  final double bothRatio;

  const DiaperStatistics({
    required this.dailyAverageCount,
    required this.changeCount,
    required this.dailyCounts,
    required this.wetRatio,
    required this.dirtyRatio,
    required this.bothRatio,
  });

  factory DiaperStatistics.empty() {
    return const DiaperStatistics(
      dailyAverageCount: 0,
      changeCount: 0,
      dailyCounts: [0, 0, 0, 0, 0, 0, 0],
      wetRatio: 0,
      dirtyRatio: 0,
      bothRatio: 0,
    );
  }

  /// 변화 유형 반환
  ChangeType get changeType {
    if (changeCount > 0) return ChangeType.increase;
    if (changeCount < 0) return ChangeType.decrease;
    return ChangeType.neutral;
  }
}

/// 울음 통계
class CryingStatistics {
  /// 이번 주 총 울음 횟수
  final int totalCount;

  /// 일 평균 울음 횟수
  final double dailyAverageCount;

  /// 요일별 울음 횟수 (월~일)
  final List<int> dailyCounts;

  /// 배고픔 비율 (0.0 ~ 1.0)
  final double hungryRatio;

  /// 졸림 비율 (0.0 ~ 1.0)
  final double tiredRatio;

  /// 가스 비율 (0.0 ~ 1.0)
  final double gasRatio;

  /// 불편 비율 (0.0 ~ 1.0)
  final double discomfortRatio;

  /// 기타 비율 (0.0 ~ 1.0)
  final double otherRatio;

  const CryingStatistics({
    required this.totalCount,
    required this.dailyAverageCount,
    required this.dailyCounts,
    required this.hungryRatio,
    required this.tiredRatio,
    required this.gasRatio,
    required this.discomfortRatio,
    required this.otherRatio,
  });

  factory CryingStatistics.empty() {
    return const CryingStatistics(
      totalCount: 0,
      dailyAverageCount: 0,
      dailyCounts: [0, 0, 0, 0, 0, 0, 0],
      hungryRatio: 0,
      tiredRatio: 0,
      gasRatio: 0,
      discomfortRatio: 0,
      otherRatio: 0,
    );
  }
}

/// 놀이 통계
class PlayStatistics {
  /// 일 평균 놀이 시간 (분 단위)
  final double dailyAverageMinutes;

  /// 지난주 대비 변화 (분 단위, 양수=증가, 음수=감소)
  final int changeMinutes;

  /// 요일별 놀이 시간 (월~일, 분 단위)
  final List<int> dailyMinutes;

  const PlayStatistics({
    required this.dailyAverageMinutes,
    required this.changeMinutes,
    required this.dailyMinutes,
  });

  factory PlayStatistics.empty() {
    return const PlayStatistics(
      dailyAverageMinutes: 0,
      changeMinutes: 0,
      dailyMinutes: [0, 0, 0, 0, 0, 0, 0],
    );
  }

  /// 변화 유형 반환
  ChangeType get changeType {
    if (changeMinutes > 0) return ChangeType.increase;
    if (changeMinutes < 0) return ChangeType.decrease;
    return ChangeType.neutral;
  }
}

/// 변화 유형
enum ChangeType {
  increase,
  decrease,
  neutral,
}

/// 리포트 유형
enum ReportType {
  sleep,
  feeding,
  diaper,
  crying,
}
