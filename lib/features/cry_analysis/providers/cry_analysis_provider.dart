import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/baby_model.dart';
import '../models/models.dart';
import '../services/services.dart';

/// 울음 분석 Provider
///
/// Phase 2: AI 울음 분석 기능
/// 울음 분석 상태 관리 및 비즈니스 로직
class CryAnalysisProvider extends ChangeNotifier {
  final AudioInputService _audioService = AudioInputService();
  final AudioPreprocessor _preprocessor = AudioPreprocessor();
  final CryClassifier _classifier = CryClassifier();
  final PretermAdjustment _pretermAdjustment = PretermAdjustment();
  final Uuid _uuid = const Uuid();

  /// 현재 상태
  CryAnalysisState _state = CryAnalysisState.idle;
  CryAnalysisState get state => _state;

  /// 최근 분석 결과
  CryAnalysisResult? _lastResult;
  CryAnalysisResult? get lastResult => _lastResult;

  /// 분석 기록 (메모리 캐시)
  final List<CryAnalysisRecord> _records = [];
  List<CryAnalysisRecord> get records => List.unmodifiable(_records);

  /// 오늘 분석 횟수
  int _todayCount = 0;
  int get todayCount => _todayCount;

  /// Freemium 일일 한도
  static const int freeUserDailyLimit = 5;
  static const int premiumUserDailyLimit = 999999; // 사실상 무제한

  /// 프리미엄 여부 (TODO: 실제 구독 상태 연동)
  bool _isPremium = false;
  bool get isPremium => _isPremium;

  /// 일일 한도 초과 여부
  bool get isLimitExceeded {
    final limit = _isPremium ? premiumUserDailyLimit : freeUserDailyLimit;
    return _todayCount >= limit;
  }

  /// 남은 분석 횟수
  int get remainingAnalyses {
    final limit = _isPremium ? premiumUserDailyLimit : freeUserDailyLimit;
    return (limit - _todayCount).clamp(0, limit);
  }

  /// 에러 메시지
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 초기화
  Future<void> initialize() async {
    debugPrint('[CryAnalysisProvider] Initializing...');

    await _audioService.initialize();
    await _preprocessor.initialize();

    // Cold Start 방지: 백그라운드에서 모델 Warm-up
    Future.microtask(() async {
      await _classifier.warmUp();
    });

    _loadTodayCount();

    debugPrint('[CryAnalysisProvider] Initialized');
  }

  /// 오늘 분석 횟수 로드 (TODO: SharedPreferences 연동)
  void _loadTodayCount() {
    // TODO: 실제 구현 시 SharedPreferences에서 로드
    _todayCount = 0;
  }

  /// 오늘 분석 횟수 저장
  void _saveTodayCount() {
    // TODO: 실제 구현 시 SharedPreferences에 저장
  }

  /// 프리미엄 상태 설정
  void setPremium(bool value) {
    if (_isPremium == value) return;
    _isPremium = value;
    notifyListeners();
  }

  /// 울음 분석 시작
  ///
  /// [baby]: 분석 대상 아기
  /// [familyId]: 가족 ID
  Future<CryAnalysisResult?> startAnalysis({
    required BabyModel baby,
    required String familyId,
  }) async {
    // 상태 체크
    if (_state == CryAnalysisState.recording ||
        _state == CryAnalysisState.analyzing) {
      debugPrint('[CryAnalysisProvider] Already in progress');
      return null;
    }

    // 일일 한도 체크
    if (isLimitExceeded) {
      _errorMessage = 'daily_limit_exceeded';
      _state = CryAnalysisState.error;
      notifyListeners();
      return null;
    }

    _errorMessage = null;
    _state = CryAnalysisState.recording;
    notifyListeners();

    try {
      // 1. 녹음 시작
      final started = await _audioService.startRecording();
      if (!started) {
        throw Exception('microphone_permission_required');
      }

      // 2. 녹음 완료 대기 (자동 또는 수동 중지)
      // UI에서 stopRecording() 호출 시 진행

      return null; // 녹음 중에는 결과 없음
    } catch (e) {
      debugPrint('[ERR] [CryAnalysisProvider] Recording start failed: $e');
      _handleError('CRY_RECORDING_FAILED');
      return null;
    }
  }

  /// 녹음 중지 및 분석 실행
  Future<CryAnalysisResult?> stopAndAnalyze({
    required BabyModel baby,
    required String familyId,
  }) async {
    if (_state != CryAnalysisState.recording) {
      debugPrint('[CryAnalysisProvider] Not recording');
      return null;
    }

    _state = CryAnalysisState.analyzing;
    notifyListeners();

    try {
      // 1. 녹음 중지
      final recording = await _audioService.stopRecording();
      if (recording == null || !recording.isValid) {
        throw Exception('recording_too_short');
      }

      // 2. 전처리 (Mel Spectrogram)
      final melSpectrogram = await _preprocessor.process(
        recording.audioData,
        recording.sampleRate,
      );

      // 3. 분류
      var result = await _classifier.classify(melSpectrogram);

      // 4. 조산아 보정
      if (baby.isPreterm) {
        result = _pretermAdjustment.adjust(
          result: result,
          correctedAgeWeeks: baby.correctedAgeInWeeks,
          isPreterm: true,
        );
      }

      // 5. 결과 저장
      _lastResult = result;
      _todayCount++;
      _saveTodayCount();

      // 6. 기록 생성
      final record = CryAnalysisRecord(
        id: _uuid.v4(),
        babyId: baby.id,
        familyId: familyId,
        result: result,
        analyzedAt: DateTime.now(),
      );
      _records.insert(0, record);

      // 히스토리 제한 (최근 100개만)
      if (_records.length > 100) {
        _records.removeRange(100, _records.length);
      }

      _state = CryAnalysisState.completed;
      notifyListeners();

      return result;
    } catch (e) {
      debugPrint('[ERR] [CryAnalysisProvider] Analysis failed: $e');
      _handleError('CRY_ANALYSIS_FAILED');
      return null;
    }
  }

  /// 녹음 취소
  void cancelRecording() {
    _audioService.cancelRecording();
    _state = CryAnalysisState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// 결과 초기화 (새 분석 준비)
  void resetResult() {
    _lastResult = null;
    _state = CryAnalysisState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// 피드백 추가
  void addFeedback(String recordId, CryFeedback feedback) {
    final index = _records.indexWhere((r) => r.id == recordId);
    if (index != -1) {
      _records[index] = _records[index].withFeedback(feedback);
      notifyListeners();
    }
  }

  /// 특정 아기의 기록만 필터링
  List<CryAnalysisRecord> getRecordsForBaby(String babyId) {
    return _records.where((r) => r.babyId == babyId).toList();
  }

  /// 오늘 기록만 필터링
  List<CryAnalysisRecord> getTodayRecords() {
    return _records.where((r) => r.isToday).toList();
  }

  /// 특정 아기의 통계
  CryAnalysisStats getStatsForBaby(String babyId) {
    final babyRecords = getRecordsForBaby(babyId);
    return CryAnalysisStats.fromRecords(babyRecords);
  }

  /// 오류 처리
  void _handleError(String message) {
    debugPrint('[CryAnalysisProvider] Error: $message');
    _errorMessage = message;
    _state = CryAnalysisState.error;
    notifyListeners();
  }

  /// 에러 상태 클리어
  void clearError() {
    _errorMessage = null;
    _state = CryAnalysisState.idle;
    notifyListeners();
  }

  /// 리소스 해제
  @override
  void dispose() {
    _audioService.dispose();
    _preprocessor.dispose();
    _classifier.dispose();
    super.dispose();
  }
}

/// 울음 분석 상태
enum CryAnalysisState {
  /// 대기 중
  idle,

  /// 녹음 중
  recording,

  /// 분석 중
  analyzing,

  /// 분석 완료
  completed,

  /// 오류
  error,
}
