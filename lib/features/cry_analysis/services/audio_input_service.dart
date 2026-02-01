import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// 오디오 입력 서비스
///
/// Phase 2: AI 울음 분석 기능
/// 마이크 권한 관리 및 오디오 녹음 담당
///
/// Privacy-First 원칙:
/// - 모든 처리 100% On-Device
/// - 오디오 파일 저장 없음 (분석 후 즉시 삭제)
/// - 서버 전송 없음
class AudioInputService {
  /// 싱글톤 인스턴스
  static final AudioInputService _instance = AudioInputService._internal();
  factory AudioInputService() => _instance;
  AudioInputService._internal();

  /// record 패키지 인스턴스
  final AudioRecorder _recorder = AudioRecorder();

  /// 녹음 상태
  AudioInputState _state = AudioInputState.idle;
  AudioInputState get state => _state;

  /// 녹음 중 여부
  bool get isRecording => _state == AudioInputState.recording;

  /// 권한 상태
  MicrophonePermission _permission = MicrophonePermission.unknown;
  MicrophonePermission get permission => _permission;

  /// 임시 파일 경로
  String? _tempFilePath;

  /// 설정
  static const int sampleRate = 16000; // 16kHz (음성 인식 표준)
  static const int bitDepth = 16; // 16-bit
  static const int channelCount = 1; // Mono
  static const Duration recordDuration = Duration(seconds: 3);
  static const Duration minRecordingDuration = Duration(seconds: 2);

  /// 초기화
  Future<void> initialize() async {
    debugPrint('[AudioInputService] Initializing...');
    await checkPermission();
  }

  /// 마이크 권한 요청
  Future<MicrophonePermission> requestPermission() async {
    debugPrint('[AudioInputService] Requesting microphone permission...');

    try {
      final hasPermission = await _recorder.hasPermission();

      if (hasPermission) {
        _permission = MicrophonePermission.granted;
      } else {
        _permission = MicrophonePermission.denied;
      }

      debugPrint('[AudioInputService] Permission: $_permission');
      return _permission;
    } catch (e) {
      debugPrint('[AudioInputService] Permission error: $e');
      _permission = MicrophonePermission.denied;
      return _permission;
    }
  }

  /// 권한 확인
  Future<MicrophonePermission> checkPermission() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      _permission = hasPermission
          ? MicrophonePermission.granted
          : MicrophonePermission.unknown;
      return _permission;
    } catch (e) {
      debugPrint('[AudioInputService] Check permission error: $e');
      _permission = MicrophonePermission.unknown;
      return _permission;
    }
  }

  /// 3초 녹음 후 결과 반환
  ///
  /// 실제 마이크로 3초간 녹음하고 PCM 데이터를 반환합니다.
  /// 녹음 파일은 분석 후 즉시 삭제됩니다.
  Future<AudioRecordingResult?> recordForAnalysis() async {
    if (_state == AudioInputState.recording) {
      debugPrint('[AudioInputService] Already recording');
      return null;
    }

    // 권한 확인
    if (_permission != MicrophonePermission.granted) {
      final result = await requestPermission();
      if (result != MicrophonePermission.granted) {
        debugPrint('[AudioInputService] Permission denied');
        _state = AudioInputState.error;
        return null;
      }
    }

    debugPrint('[AudioInputService] Starting 3-second recording...');
    _state = AudioInputState.recording;

    try {
      // 임시 파일 경로 생성
      final tempDir = await getTemporaryDirectory();
      _tempFilePath =
          '${tempDir.path}/cry_analysis_${DateTime.now().millisecondsSinceEpoch}.wav';

      // 녹음 설정
      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: sampleRate,
        numChannels: channelCount,
        bitRate: sampleRate * bitDepth * channelCount,
      );

      // 녹음 시작
      await _recorder.start(config, path: _tempFilePath!);

      // 3초 대기
      await Future.delayed(recordDuration);

      // 녹음 중지
      final path = await _recorder.stop();
      _state = AudioInputState.processing;

      if (path == null) {
        debugPrint('[AudioInputService] Recording failed: no path');
        _state = AudioInputState.error;
        return null;
      }

      debugPrint('[AudioInputService] Recording saved to: $path');

      // WAV 파일에서 PCM 데이터 추출
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('[AudioInputService] Recording file not found');
        _state = AudioInputState.error;
        return null;
      }

      final fileBytes = await file.readAsBytes();

      // WAV 헤더 건너뛰기 (44 bytes)
      final pcmData = fileBytes.length > 44
          ? Uint8List.fromList(fileBytes.sublist(44))
          : fileBytes;

      // 임시 파일 삭제 (Privacy-First)
      await _deleteTempFile();

      final durationMs = (pcmData.length / (sampleRate * 2) * 1000).round();

      debugPrint(
          '[AudioInputService] Recording complete: ${durationMs}ms, ${pcmData.length} bytes');

      _state = AudioInputState.idle;

      return AudioRecordingResult(
        audioData: pcmData,
        sampleRate: sampleRate,
        bitDepth: bitDepth,
        channelCount: channelCount,
        durationMs: durationMs,
      );
    } catch (e) {
      debugPrint('[AudioInputService] Recording error: $e');
      _state = AudioInputState.error;
      await _deleteTempFile();
      return null;
    }
  }

  /// 녹음 시작 (수동 제어용)
  Future<bool> startRecording() async {
    if (_state == AudioInputState.recording) {
      debugPrint('[AudioInputService] Already recording');
      return false;
    }

    if (_permission != MicrophonePermission.granted) {
      final result = await requestPermission();
      if (result != MicrophonePermission.granted) {
        debugPrint('[AudioInputService] Permission denied');
        return false;
      }
    }

    debugPrint('[AudioInputService] Starting recording...');

    try {
      final tempDir = await getTemporaryDirectory();
      _tempFilePath =
          '${tempDir.path}/cry_analysis_${DateTime.now().millisecondsSinceEpoch}.wav';

      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: sampleRate,
        numChannels: channelCount,
        bitRate: sampleRate * bitDepth * channelCount,
      );

      await _recorder.start(config, path: _tempFilePath!);
      _state = AudioInputState.recording;

      return true;
    } catch (e) {
      debugPrint('[AudioInputService] Start recording error: $e');
      _state = AudioInputState.error;
      return false;
    }
  }

  /// 녹음 중지
  Future<AudioRecordingResult?> stopRecording() async {
    if (_state != AudioInputState.recording) {
      debugPrint('[AudioInputService] Not recording');
      return null;
    }

    debugPrint('[AudioInputService] Stopping recording...');
    _state = AudioInputState.processing;

    try {
      final path = await _recorder.stop();

      if (path == null) {
        debugPrint('[AudioInputService] Stop recording failed: no path');
        _state = AudioInputState.error;
        return null;
      }

      final file = File(path);
      if (!await file.exists()) {
        debugPrint('[AudioInputService] Recording file not found');
        _state = AudioInputState.error;
        return null;
      }

      final fileBytes = await file.readAsBytes();
      final pcmData = fileBytes.length > 44
          ? Uint8List.fromList(fileBytes.sublist(44))
          : fileBytes;

      await _deleteTempFile();

      final durationMs = (pcmData.length / (sampleRate * 2) * 1000).round();

      _state = AudioInputState.idle;

      return AudioRecordingResult(
        audioData: pcmData,
        sampleRate: sampleRate,
        bitDepth: bitDepth,
        channelCount: channelCount,
        durationMs: durationMs,
      );
    } catch (e) {
      debugPrint('[AudioInputService] Stop recording error: $e');
      _state = AudioInputState.error;
      await _deleteTempFile();
      return null;
    }
  }

  /// 녹음 취소
  Future<void> cancelRecording() async {
    debugPrint('[AudioInputService] Cancelling recording...');

    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (e) {
      debugPrint('[AudioInputService] Cancel recording error: $e');
    }

    await _deleteTempFile();
    _state = AudioInputState.idle;
  }

  /// 임시 파일 삭제
  Future<void> _deleteTempFile() async {
    if (_tempFilePath != null) {
      try {
        final file = File(_tempFilePath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint('[AudioInputService] Temp file deleted');
        }
      } catch (e) {
        debugPrint('[AudioInputService] Delete temp file error: $e');
      }
      _tempFilePath = null;
    }
  }

  /// 리소스 해제
  Future<void> dispose() async {
    await cancelRecording();
    await _recorder.dispose();
    _state = AudioInputState.idle;
  }
}

/// 오디오 입력 상태
enum AudioInputState {
  /// 대기 중
  idle,

  /// 녹음 중
  recording,

  /// 처리 중
  processing,

  /// 오류
  error,
}

/// 마이크 권한 상태
enum MicrophonePermission {
  /// 알 수 없음 (확인 전)
  unknown,

  /// 허용됨
  granted,

  /// 거부됨
  denied,

  /// 영구 거부 (설정에서 변경 필요)
  permanentlyDenied,

  /// 제한됨 (iOS 자녀 보호 등)
  restricted,
}

/// 녹음 결과
class AudioRecordingResult {
  /// PCM 오디오 데이터
  final Uint8List audioData;

  /// 샘플레이트 (Hz)
  final int sampleRate;

  /// 비트 깊이
  final int bitDepth;

  /// 채널 수
  final int channelCount;

  /// 녹음 길이 (ms)
  final int durationMs;

  const AudioRecordingResult({
    required this.audioData,
    required this.sampleRate,
    required this.bitDepth,
    required this.channelCount,
    required this.durationMs,
  });

  /// 녹음 길이 (초)
  double get durationSeconds => durationMs / 1000;

  /// 유효한 녹음 여부 (2초 이상)
  bool get isValid => durationMs >= 2000;

  /// 데이터 크기 (bytes)
  int get dataSizeBytes => audioData.length;

  @override
  String toString() {
    return 'AudioRecordingResult(duration: ${durationSeconds}s, '
        'size: ${dataSizeBytes}bytes, rate: ${sampleRate}Hz)';
  }
}
