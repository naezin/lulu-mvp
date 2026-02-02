/// AI 인사이트 데이터 모델
///
/// 작업 지시서 v1.2.1: 통계 화면 AI 인사이트용
class InsightData {
  /// 인사이트 메시지
  final String message;

  /// 인사이트 유형
  final InsightType type;

  /// 관련 리포트 유형 (null이면 전체)
  final String? relatedReportType;

  /// 하이라이트 요일 (0=월, 6=일, null=없음)
  final int? highlightDayIndex;

  const InsightData({
    required this.message,
    required this.type,
    this.relatedReportType,
    this.highlightDayIndex,
  });

  /// 빈 인사이트
  factory InsightData.empty() {
    return const InsightData(
      message: '',
      type: InsightType.neutral,
    );
  }
}

/// 인사이트 유형
enum InsightType {
  /// 긍정적 (패턴 안정, 규칙적 등)
  positive,

  /// 중립적 (일반 정보)
  neutral,

  /// 주의 (변화 감지 등)
  attention,
}

/// 함께 보기용 인사이트 (다태아)
class TogetherInsightData {
  /// 첫 번째 아기 이름
  final String baby1Name;

  /// 두 번째 아기 이름
  final String baby2Name;

  /// 인사이트 메시지 (비교 없이 "패턴이 달라요" 형식)
  final String message;

  /// 첫 번째 아기 특성 설명
  final String baby1Description;

  /// 두 번째 아기 특성 설명
  final String baby2Description;

  const TogetherInsightData({
    required this.baby1Name,
    required this.baby2Name,
    required this.message,
    required this.baby1Description,
    required this.baby2Description,
  });

  /// 빈 인사이트
  factory TogetherInsightData.empty() {
    return const TogetherInsightData(
      baby1Name: '',
      baby2Name: '',
      message: '',
      baby1Description: '',
      baby2Description: '',
    );
  }
}
