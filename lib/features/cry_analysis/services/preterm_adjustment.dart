import '../models/models.dart';

/// 조산아 신뢰도 보정 서비스
///
/// Phase 2: AI 울음 분석 기능
/// 교정연령에 따른 신뢰도 조정
///
/// 의학적 근거:
/// - 조산아의 울음 패턴은 만삭아와 다를 수 있음
/// - 교정연령이 낮을수록 Dunstan 패턴 적합도 낮음
/// - 40주 이후부터 점진적으로 만삭아 패턴에 근접
class PretermAdjustment {
  /// 싱글톤 인스턴스
  static final PretermAdjustment _instance = PretermAdjustment._internal();
  factory PretermAdjustment() => _instance;
  PretermAdjustment._internal();

  /// 신뢰도 조정 계수
  ///
  /// 교정연령(주) → 신뢰도 보정 계수
  /// - 0주 미만: 0.6 (60%)
  /// - 0-4주: 0.7 (70%)
  /// - 4-8주: 0.8 (80%)
  /// - 8-12주: 0.9 (90%)
  /// - 12주 이상: 1.0 (100%) - 보정 없음
  static const Map<int, double> _adjustmentFactors = {
    -1: 0.60, // 0주 미만 (음수 교정연령)
    0: 0.70, // 0-4주
    4: 0.80, // 4-8주
    8: 0.90, // 8-12주
    12: 1.00, // 12주 이상
  };

  /// 신뢰도 보정 적용
  ///
  /// [result]: 원본 분석 결과
  /// [correctedAgeWeeks]: 교정연령 (주), null이면 만삭아
  /// [isPreterm]: 조산아 여부
  /// Returns: 보정된 분석 결과
  CryAnalysisResult adjust({
    required CryAnalysisResult result,
    int? correctedAgeWeeks,
    bool isPreterm = false,
  }) {
    // 만삭아이거나 교정연령이 없으면 보정 없음
    if (!isPreterm || correctedAgeWeeks == null) {
      return result;
    }

    // 보정 계수 계산
    final factor = _getAdjustmentFactor(correctedAgeWeeks);

    // 보정 계수가 1.0이면 변경 없음
    if (factor >= 1.0) {
      return result;
    }

    // 신뢰도 보정
    final adjustedConfidence = result.confidence * factor;

    // 확률 분포 보정 (비례적으로)
    final adjustedProbabilities = result.probabilities.map(
      (type, prob) => MapEntry(type, prob * factor),
    );

    // Unknown 확률 재분배 (보정으로 줄어든 만큼)
    final unknownIncrease = 1.0 - factor;
    final currentUnknown = adjustedProbabilities[CryType.unknown] ?? 0.0;
    adjustedProbabilities[CryType.unknown] = currentUnknown + unknownIncrease;

    // 정규화 (합이 1이 되도록)
    final sum = adjustedProbabilities.values.reduce((a, b) => a + b);
    final normalizedProbabilities = adjustedProbabilities.map(
      (type, prob) => MapEntry(type, prob / sum),
    );

    return result.copyWith(
      confidence: adjustedConfidence.clamp(0.0, 1.0),
      probabilities: normalizedProbabilities,
      isPretermAdjusted: true,
      correctedAgeWeeks: correctedAgeWeeks,
    );
  }

  /// 보정 계수 계산
  double _getAdjustmentFactor(int correctedAgeWeeks) {
    if (correctedAgeWeeks < 0) return _adjustmentFactors[-1]!;
    if (correctedAgeWeeks < 4) return _adjustmentFactors[0]!;
    if (correctedAgeWeeks < 8) return _adjustmentFactors[4]!;
    if (correctedAgeWeeks < 12) return _adjustmentFactors[8]!;
    return _adjustmentFactors[12]!;
  }

  /// 보정 계수 설명 텍스트
  String getAdjustmentDescription(int? correctedAgeWeeks, bool isPreterm) {
    if (!isPreterm || correctedAgeWeeks == null) {
      return '만삭아 기준으로 분석했어요.';
    }

    final factor = _getAdjustmentFactor(correctedAgeWeeks);
    final percentage = (factor * 100).round();

    if (factor >= 1.0) {
      return '교정연령 $correctedAgeWeeks주로, 만삭아와 유사한 신뢰도예요.';
    }

    return '교정연령 $correctedAgeWeeks주 기준, '
        '신뢰도를 $percentage%로 보정했어요.\n'
        '조산아의 울음 패턴은 만삭아와 다를 수 있어요.';
  }

  /// 보정 필요 여부 확인
  bool needsAdjustment(int? correctedAgeWeeks, bool isPreterm) {
    if (!isPreterm || correctedAgeWeeks == null) return false;
    return correctedAgeWeeks < 12;
  }

  /// 의료 면책 문구
  static const String medicalDisclaimer = '이 분석 결과는 참고용이며, '
      '의료적 조언을 대체하지 않습니다. '
      '조산아의 울음 패턴은 개인차가 크므로, '
      '걱정되시면 담당 의료진과 상담하세요.';
}
