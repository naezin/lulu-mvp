import '../../../l10n/generated/app_localizations.dart' show S;
import 'cry_type.dart';

/// 울음 분석 결과 모델
///
/// Phase 2: AI 울음 분석 기능
/// 단일 분석 결과를 나타내는 불변 모델
class CryAnalysisResult {
  /// 분석된 울음 타입
  final CryType cryType;

  /// 신뢰도 (0.0 ~ 1.0)
  final double confidence;

  /// 분석 시간 (milliseconds)
  final int analysisTimeMs;

  /// 원본 확률 분포 (각 타입별 확률)
  final Map<CryType, double> probabilities;

  /// 조산아 보정 적용 여부
  final bool isPretermAdjusted;

  /// 적용된 교정연령 (주)
  final int? correctedAgeWeeks;

  /// 모델 버전
  final String modelVersion;

  const CryAnalysisResult({
    required this.cryType,
    required this.confidence,
    required this.analysisTimeMs,
    required this.probabilities,
    this.isPretermAdjusted = false,
    this.correctedAgeWeeks,
    this.modelVersion = '1.0.0',
  });

  /// 신뢰도 백분율 (0 ~ 100)
  int get confidencePercent => (confidence * 100).round();

  /// 고신뢰도 여부 (70% 이상)
  bool get isHighConfidence => confidence >= 0.70;

  /// 중신뢰도 여부 (50% ~ 70%)
  bool get isMediumConfidence => confidence >= 0.50 && confidence < 0.70;

  /// 저신뢰도 여부 (50% 미만)
  bool get isLowConfidence => confidence < 0.50;

  /// 신뢰도 레벨 텍스트
  String localizedConfidenceLevel(S? l10n) {
    if (isHighConfidence) return l10n?.confidenceLevelHigh ?? 'High';
    if (isMediumConfidence) return l10n?.confidenceLevelMedium ?? 'Medium';
    return l10n?.confidenceLevelLow ?? 'Low';
  }

  String get confidenceLevel => localizedConfidenceLevel(null);

  /// 신뢰도 레벨 텍스트 (영어)
  String get confidenceLevelEn {
    if (isHighConfidence) return 'High';
    if (isMediumConfidence) return 'Medium';
    return 'Low';
  }

  /// 상위 N개 결과 가져오기
  List<MapEntry<CryType, double>> getTopResults(int n) {
    final sorted = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).toList();
  }

  /// 2위 결과
  CryType? get secondCryType {
    final top2 = getTopResults(2);
    return top2.length > 1 ? top2[1].key : null;
  }

  /// 2위 신뢰도
  double? get secondConfidence {
    final top2 = getTopResults(2);
    return top2.length > 1 ? top2[1].value : null;
  }

  /// Unknown 결과 생성 (분석 실패 시)
  factory CryAnalysisResult.unknown({
    int analysisTimeMs = 0,
    String modelVersion = '1.0.0',
  }) {
    return CryAnalysisResult(
      cryType: CryType.unknown,
      confidence: 0.0,
      analysisTimeMs: analysisTimeMs,
      probabilities: {
        for (final type in CryType.values) type: type == CryType.unknown ? 1.0 : 0.0,
      },
      modelVersion: modelVersion,
    );
  }

  /// Mock 결과 생성 (테스트용)
  factory CryAnalysisResult.mock({
    CryType cryType = CryType.hungry,
    double confidence = 0.85,
  }) {
    final probabilities = <CryType, double>{};
    double remaining = 1.0 - confidence;

    for (final type in CryType.values) {
      if (type == cryType) {
        probabilities[type] = confidence;
      } else if (type != CryType.unknown) {
        probabilities[type] = remaining / 4;
      } else {
        probabilities[type] = 0.0;
      }
    }

    return CryAnalysisResult(
      cryType: cryType,
      confidence: confidence,
      analysisTimeMs: 150,
      probabilities: probabilities,
      modelVersion: '1.0.0-mock',
    );
  }

  /// JSON 변환
  factory CryAnalysisResult.fromJson(Map<String, dynamic> json) {
    return CryAnalysisResult(
      cryType: CryType.fromValue(json['cryType'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      analysisTimeMs: json['analysisTimeMs'] as int,
      probabilities: (json['probabilities'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          CryType.fromValue(key),
          (value as num).toDouble(),
        ),
      ),
      isPretermAdjusted: json['isPretermAdjusted'] as bool? ?? false,
      correctedAgeWeeks: json['correctedAgeWeeks'] as int?,
      modelVersion: json['modelVersion'] as String? ?? '1.0.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cryType': cryType.value,
      'confidence': confidence,
      'analysisTimeMs': analysisTimeMs,
      'probabilities': probabilities.map(
        (key, value) => MapEntry(key.value, value),
      ),
      'isPretermAdjusted': isPretermAdjusted,
      if (correctedAgeWeeks != null) 'correctedAgeWeeks': correctedAgeWeeks,
      'modelVersion': modelVersion,
    };
  }

  /// 복사 (불변성 유지)
  CryAnalysisResult copyWith({
    CryType? cryType,
    double? confidence,
    int? analysisTimeMs,
    Map<CryType, double>? probabilities,
    bool? isPretermAdjusted,
    int? correctedAgeWeeks,
    String? modelVersion,
  }) {
    return CryAnalysisResult(
      cryType: cryType ?? this.cryType,
      confidence: confidence ?? this.confidence,
      analysisTimeMs: analysisTimeMs ?? this.analysisTimeMs,
      probabilities: probabilities ?? Map.from(this.probabilities),
      isPretermAdjusted: isPretermAdjusted ?? this.isPretermAdjusted,
      correctedAgeWeeks: correctedAgeWeeks ?? this.correctedAgeWeeks,
      modelVersion: modelVersion ?? this.modelVersion,
    );
  }

  @override
  String toString() {
    return 'CryAnalysisResult(type: ${cryType.value}, '
        'confidence: $confidencePercent%, '
        'time: ${analysisTimeMs}ms, '
        'preterm: $isPretermAdjusted)';
  }
}
