import 'weekly_statistics.dart';

/// 함께 보기용 데이터 모델 (다태아)
///
/// 작업 지시서 v1.2.1: 함께 보기 뷰용 데이터
/// ⚠️ "비교" 대신 "함께 보기" 사용
class TogetherData {
  /// 아기별 통계 리스트
  final List<BabyStatisticsSummary> babies;

  /// 통계 기간 시작일
  final DateTime startDate;

  /// 통계 기간 종료일
  final DateTime endDate;

  const TogetherData({
    required this.babies,
    required this.startDate,
    required this.endDate,
  });

  /// 빈 데이터
  factory TogetherData.empty() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return TogetherData(
      babies: [],
      startDate: weekAgo,
      endDate: now,
    );
  }

  /// 아기 2명 이상인지 확인
  bool get hasMultipleBabies => babies.length >= 2;
}

/// 개별 아기 통계 요약
class BabyStatisticsSummary {
  /// 아기 ID
  final String babyId;

  /// 아기 이름
  final String babyName;

  /// 교정연령 (일 단위, null이면 만삭)
  final int? correctedAgeDays;

  /// 주간 통계
  final WeeklyStatistics statistics;

  const BabyStatisticsSummary({
    required this.babyId,
    required this.babyName,
    this.correctedAgeDays,
    required this.statistics,
  });

  /// 조산아 여부
  bool get isPremature => correctedAgeDays != null;

  /// 교정연령 문자열 (예: "교정 42일")
  String? get correctedAgeLabel {
    if (correctedAgeDays == null) return null;
    return 'Corrected ${correctedAgeDays}d';
  }
}
