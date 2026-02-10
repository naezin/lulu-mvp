import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/models.dart';

/// 울음 분류 서비스
///
/// Phase 2: AI 울음 분석 기능
/// TensorFlow Lite 모델을 사용한 울음 분류
///
/// Fallback 전략:
/// - 모델 파일 있으면 → 실제 TFLite 추론
/// - 모델 파일 없으면 → Mock 결과 반환 (개발용)
///
/// 아키텍처:
/// - Input: 128x128x1 Mel Spectrogram
/// - CNN: Conv2D → MaxPool → Conv2D → MaxPool → Flatten → Dense
/// - Output: 6-class Softmax (5 cry types + unknown)
class CryClassifier {
  /// 싱글톤 인스턴스
  static final CryClassifier _instance = CryClassifier._internal();
  factory CryClassifier() => _instance;
  CryClassifier._internal();

  /// TFLite Interpreter
  Interpreter? _interpreter;

  /// 모델 로드 상태
  bool _isModelLoaded = false;
  bool get isModelLoaded => _isModelLoaded;

  /// Mock 모드 여부 (모델 파일 없을 때)
  bool _isMockMode = false;
  bool get isMockMode => _isMockMode;

  /// 모델 버전
  String _modelVersion = 'unknown';
  String get modelVersion => _modelVersion;

  /// 모델 파일 경로
  static const String modelAssetPath = 'assets/models/cry_classifier.tflite';

  /// 입력 크기
  static const int inputHeight = 128;
  static const int inputWidth = 128;
  static const int inputChannels = 1;

  /// 출력 클래스 수
  static const int numClasses = 6;

  /// 최소 신뢰도 임계값
  static const double minConfidenceThreshold = 0.30;

  /// Warm-up 완료 여부
  bool _isWarmedUp = false;
  bool get isWarmedUp => _isWarmedUp;

  /// 클래스 인덱스 → CryType 매핑
  static const List<CryType> _classIndexToType = [
    CryType.hungry, // 0: hu (hungry)
    CryType.tired, // 1: ti (tired)
    CryType.discomfort, // 2: dc (discomfort)
    CryType.gas, // 3: bp (belly_pain / gas)
    CryType.burp, // 4: bu (burping)
    CryType.unknown, // 5: unknown
  ];

  /// 모델 로드
  ///
  /// Graceful Fallback: 모델 파일이 없으면 Mock 모드로 동작
  Future<bool> loadModel() async {
    if (_isModelLoaded) return true;

    debugPrint('[CryClassifier] Loading model...');

    try {
      // 모델 파일 존재 확인
      final modelExists = await _checkModelExists();

      if (!modelExists) {
        debugPrint(
            '[CryClassifier] [WARN] Model file not found, using Mock mode');
        _isMockMode = true;
        _isModelLoaded = true;
        _modelVersion = '1.0.0-mock';
        return true;
      }

      // TFLite 모델 로드
      _interpreter = await Interpreter.fromAsset(modelAssetPath);
      _isMockMode = false;
      _isModelLoaded = true;
      _modelVersion = '1.0.0-tflite';

      // 모델 정보 출력
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      debugPrint('[CryClassifier] Model loaded successfully');
      debugPrint('[CryClassifier] Input shape: $inputShape');
      debugPrint('[CryClassifier] Output shape: $outputShape');

      return true;
    } catch (e) {
      debugPrint('[CryClassifier] [WARN] Model load failed: $e');
      debugPrint('[CryClassifier] Falling back to Mock mode');
      _isMockMode = true;
      _isModelLoaded = true;
      _modelVersion = '1.0.0-mock';
      return true;
    }
  }

  /// 모델 파일 존재 확인
  Future<bool> _checkModelExists() async {
    try {
      await rootBundle.load(modelAssetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 모델 Warm-up (Cold Start 방지)
  ///
  /// 앱 시작 시 호출하여 첫 추론 지연 방지
  Future<void> warmUp() async {
    if (_isWarmedUp) return;

    debugPrint('[CryClassifier] Warming up...');
    await loadModel();

    // 더미 추론으로 Warm-up
    final dummyInput = Float32List(inputHeight * inputWidth);
    await classify(dummyInput);

    _isWarmedUp = true;
    debugPrint('[CryClassifier] Warm-up complete (Mock mode: $_isMockMode)');
  }

  /// 울음 분류
  ///
  /// [melSpectrogram]: 128x128 Mel Spectrogram (Float32)
  /// Returns: 분류 결과
  Future<CryAnalysisResult> classify(Float32List melSpectrogram) async {
    if (!_isModelLoaded) {
      await loadModel();
    }

    debugPrint('[CryClassifier] Classifying... (Mock mode: $_isMockMode)');
    final stopwatch = Stopwatch()..start();

    // 입력 검증
    if (melSpectrogram.length != inputHeight * inputWidth) {
      debugPrint(
          '[CryClassifier] Invalid input size: ${melSpectrogram.length}');
      return CryAnalysisResult.unknown(
        analysisTimeMs: stopwatch.elapsedMilliseconds,
        modelVersion: _modelVersion,
      );
    }

    Map<CryType, double> probabilities;

    if (_isMockMode || _interpreter == null) {
      // Mock 추론
      probabilities = _mockInference(melSpectrogram);
    } else {
      // 실제 TFLite 추론
      probabilities = await _realInference(melSpectrogram);
    }

    stopwatch.stop();

    // 결과 변환
    final result = _convertToResult(
      probabilities,
      stopwatch.elapsedMilliseconds,
    );

    debugPrint('[CryClassifier] Result: ${result.cryType.value} '
        '(${result.confidencePercent}%) in ${result.analysisTimeMs}ms');

    return result;
  }

  /// 실제 TFLite 추론
  Future<Map<CryType, double>> _realInference(Float32List input) async {
    if (_interpreter == null) {
      return _mockInference(input);
    }

    try {
      // 입력 텐서 준비 [1, 128, 128, 1]
      final inputTensor = input.reshape([1, inputHeight, inputWidth, 1]);

      // 출력 텐서 준비
      final outputTensor = List.filled(1, List.filled(numClasses, 0.0));

      // 추론 실행
      _interpreter!.run(inputTensor, outputTensor);

      // 결과 변환
      final probabilities = <CryType, double>{};
      for (int i = 0; i < numClasses; i++) {
        probabilities[_classIndexToType[i]] = outputTensor[0][i];
      }

      return probabilities;
    } catch (e) {
      debugPrint('[CryClassifier] Inference error: $e');
      return _mockInference(input);
    }
  }

  /// Mock 추론 (개발용)
  Map<CryType, double> _mockInference(Float32List input) {
    final random = math.Random();

    // 입력 데이터 기반 시드 생성 (일관된 결과를 위해)
    final seed = input.isNotEmpty
        ? (input[0] * 1000 + input[input.length ~/ 2] * 500).round().abs()
        : random.nextInt(1000);
    final seededRandom = math.Random(seed);

    // 랜덤 확률 생성
    final rawProbs = <CryType, double>{};
    double sum = 0;

    for (final type in CryType.values) {
      if (type == CryType.unknown) {
        rawProbs[type] = seededRandom.nextDouble() * 0.1; // Unknown은 낮게
      } else {
        rawProbs[type] = seededRandom.nextDouble();
      }
      sum += rawProbs[type]!;
    }

    // Softmax 정규화
    return rawProbs.map((key, value) => MapEntry(key, value / sum));
  }

  /// 결과 변환
  CryAnalysisResult _convertToResult(
    Map<CryType, double> probabilities,
    int analysisTimeMs,
  ) {
    // 최고 확률 타입 찾기
    CryType bestType = CryType.unknown;
    double bestProb = 0.0;

    for (final entry in probabilities.entries) {
      if (entry.value > bestProb) {
        bestProb = entry.value;
        bestType = entry.key;
      }
    }

    // 임계값 미만이면 unknown
    if (bestProb < minConfidenceThreshold) {
      bestType = CryType.unknown;
    }

    return CryAnalysisResult(
      cryType: bestType,
      confidence: bestProb,
      analysisTimeMs: analysisTimeMs,
      probabilities: probabilities,
      modelVersion: _modelVersion,
    );
  }

  /// 모델 언로드
  void unloadModel() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
    _isWarmedUp = false;
    _isMockMode = false;
    debugPrint('[CryClassifier] Model unloaded');
  }

  /// 리소스 해제
  void dispose() {
    unloadModel();
  }
}

/// Float32List reshape 확장
extension Float32ListReshape on Float32List {
  List<List<List<List<double>>>> reshape(List<int> shape) {
    assert(shape.length == 4, 'Shape must have 4 dimensions');
    assert(shape[0] * shape[1] * shape[2] * shape[3] == length,
        'Shape does not match data length');

    final result = List.generate(
      shape[0],
      (batch) => List.generate(
        shape[1],
        (height) => List.generate(
          shape[2],
          (width) => List.generate(
            shape[3],
            (channel) {
              final index =
                  batch * shape[1] * shape[2] * shape[3] +
                  height * shape[2] * shape[3] +
                  width * shape[3] +
                  channel;
              return this[index].toDouble();
            },
          ),
        ),
      ),
    );

    return result;
  }
}
