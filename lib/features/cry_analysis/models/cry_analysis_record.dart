import 'cry_type.dart';
import 'cry_analysis_result.dart';

/// 울음 분석 기록 모델 (히스토리 저장용)
///
/// Phase 2: AI 울음 분석 기능
/// 분석 결과를 영구 저장하기 위한 모델
class CryAnalysisRecord {
  /// 고유 ID
  final String id;

  /// 아기 ID
  final String babyId;

  /// 가족 ID
  final String familyId;

  /// 분석 결과
  final CryAnalysisResult result;

  /// 분석 시각
  final DateTime analyzedAt;

  /// 사용자 피드백 (정확도)
  final CryFeedback? feedback;

  /// 피드백 시각
  final DateTime? feedbackAt;

  /// 메모
  final String? note;

  /// 관련 활동 기록 ID (수유/수면 등으로 연결된 경우)
  final String? linkedActivityId;

  const CryAnalysisRecord({
    required this.id,
    required this.babyId,
    required this.familyId,
    required this.result,
    required this.analyzedAt,
    this.feedback,
    this.feedbackAt,
    this.note,
    this.linkedActivityId,
  });

  /// 울음 타입 (편의 getter)
  CryType get cryType => result.cryType;

  /// 신뢰도 (편의 getter)
  double get confidence => result.confidence;

  /// 피드백 완료 여부
  bool get hasFeedback => feedback != null;

  /// 활동 연결 여부
  bool get isLinkedToActivity => linkedActivityId != null;

  /// 오늘 기록 여부
  bool get isToday {
    final now = DateTime.now();
    return analyzedAt.year == now.year &&
        analyzedAt.month == now.month &&
        analyzedAt.day == now.day;
  }

  /// JSON 변환
  factory CryAnalysisRecord.fromJson(Map<String, dynamic> json) {
    return CryAnalysisRecord(
      id: json['id'] as String,
      babyId: json['babyId'] as String,
      familyId: json['familyId'] as String,
      result: CryAnalysisResult.fromJson(
        json['result'] as Map<String, dynamic>,
      ),
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
      feedback: json['feedback'] != null
          ? CryFeedback.fromValue(json['feedback'] as String)
          : null,
      feedbackAt: json['feedbackAt'] != null
          ? DateTime.parse(json['feedbackAt'] as String)
          : null,
      note: json['note'] as String?,
      linkedActivityId: json['linkedActivityId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'babyId': babyId,
      'familyId': familyId,
      'result': result.toJson(),
      'analyzedAt': analyzedAt.toIso8601String(),
      if (feedback != null) 'feedback': feedback!.value,
      if (feedbackAt != null) 'feedbackAt': feedbackAt!.toIso8601String(),
      if (note != null) 'note': note,
      if (linkedActivityId != null) 'linkedActivityId': linkedActivityId,
    };
  }

  /// 복사 (불변성 유지)
  CryAnalysisRecord copyWith({
    String? id,
    String? babyId,
    String? familyId,
    CryAnalysisResult? result,
    DateTime? analyzedAt,
    CryFeedback? feedback,
    DateTime? feedbackAt,
    String? note,
    String? linkedActivityId,
  }) {
    return CryAnalysisRecord(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      familyId: familyId ?? this.familyId,
      result: result ?? this.result,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      feedback: feedback ?? this.feedback,
      feedbackAt: feedbackAt ?? this.feedbackAt,
      note: note ?? this.note,
      linkedActivityId: linkedActivityId ?? this.linkedActivityId,
    );
  }

  /// 피드백 추가
  CryAnalysisRecord withFeedback(CryFeedback newFeedback) {
    return copyWith(
      feedback: newFeedback,
      feedbackAt: DateTime.now(),
    );
  }

  /// 활동 연결
  CryAnalysisRecord withLinkedActivity(String activityId) {
    return copyWith(linkedActivityId: activityId);
  }

  @override
  String toString() {
    return 'CryAnalysisRecord(id: $id, baby: $babyId, '
        'type: ${cryType.value}, confidence: ${result.confidencePercent}%)';
  }
}

/// 사용자 피드백 타입
enum CryFeedback {
  /// 정확함
  accurate('accurate'),

  /// 부정확함
  inaccurate('inaccurate'),

  /// 잘 모르겠음
  unsure('unsure');

  const CryFeedback(this.value);

  final String value;

  static CryFeedback fromValue(String value) {
    return CryFeedback.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CryFeedback.unsure,
    );
  }

  String get label {
    switch (this) {
      case CryFeedback.accurate:
        return '정확해요';
      case CryFeedback.inaccurate:
        return '다른 것 같아요';
      case CryFeedback.unsure:
        return '잘 모르겠어요';
    }
  }
}

/// 분석 기록 통계 (일별/주별 집계용)
class CryAnalysisStats {
  /// 총 분석 횟수
  final int totalCount;

  /// 타입별 횟수
  final Map<CryType, int> countByType;

  /// 평균 신뢰도
  final double avgConfidence;

  /// 정확 피드백 비율
  final double accurateFeedbackRate;

  /// 가장 많은 울음 타입
  final CryType? mostCommonType;

  const CryAnalysisStats({
    required this.totalCount,
    required this.countByType,
    required this.avgConfidence,
    required this.accurateFeedbackRate,
    this.mostCommonType,
  });

  /// 빈 통계
  factory CryAnalysisStats.empty() {
    return const CryAnalysisStats(
      totalCount: 0,
      countByType: {},
      avgConfidence: 0.0,
      accurateFeedbackRate: 0.0,
    );
  }

  /// 기록 리스트에서 통계 계산
  factory CryAnalysisStats.fromRecords(List<CryAnalysisRecord> records) {
    if (records.isEmpty) return CryAnalysisStats.empty();

    // 타입별 카운트
    final countByType = <CryType, int>{};
    double totalConfidence = 0;
    int accurateCount = 0;
    int feedbackCount = 0;

    for (final record in records) {
      countByType[record.cryType] =
          (countByType[record.cryType] ?? 0) + 1;
      totalConfidence += record.confidence;

      if (record.hasFeedback) {
        feedbackCount++;
        if (record.feedback == CryFeedback.accurate) {
          accurateCount++;
        }
      }
    }

    // 가장 많은 타입 찾기
    CryType? mostCommon;
    int maxCount = 0;
    for (final entry in countByType.entries) {
      if (entry.value > maxCount && entry.key != CryType.unknown) {
        maxCount = entry.value;
        mostCommon = entry.key;
      }
    }

    return CryAnalysisStats(
      totalCount: records.length,
      countByType: countByType,
      avgConfidence: totalConfidence / records.length,
      accurateFeedbackRate:
          feedbackCount > 0 ? accurateCount / feedbackCount : 0.0,
      mostCommonType: mostCommon,
    );
  }
}
