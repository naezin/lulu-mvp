import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// 오디오 전처리 서비스
///
/// Phase 2: AI 울음 분석 기능
/// PCM 오디오를 Mel Spectrogram으로 변환
///
/// 입력: 16kHz, 16-bit, Mono PCM
/// 출력: 128x128 Mel Spectrogram (Float32)
class AudioPreprocessor {
  /// 싱글톤 인스턴스
  static final AudioPreprocessor _instance = AudioPreprocessor._internal();
  factory AudioPreprocessor() => _instance;
  AudioPreprocessor._internal();

  /// 설정 상수
  static const int targetSampleRate = 16000;
  static const int nMels = 128; // Mel 필터 수
  static const int nFft = 2048; // FFT 크기
  static const int hopLength = 512; // 프레임 간격
  static const int targetFrames = 128; // 출력 시간 프레임 수
  static const double fMin = 0.0; // 최소 주파수
  static const double fMax = 8000.0; // 최대 주파수 (나이키스트 주파수)

  /// Mel 필터뱅크 (캐싱)
  Float32List? _melFilterbank;

  /// Hann 윈도우 (캐싱)
  Float32List? _hannWindow;

  /// 초기화
  Future<void> initialize() async {
    debugPrint('[AudioPreprocessor] Initializing...');

    // Mel 필터뱅크 생성 (한 번만)
    _melFilterbank ??= _createMelFilterbank();

    // Hann 윈도우 생성
    _hannWindow ??= _createHannWindow(nFft);

    debugPrint('[AudioPreprocessor] Initialized (nMels: $nMels, nFft: $nFft)');
  }

  /// PCM 오디오를 Mel Spectrogram으로 변환
  ///
  /// [audioData]: 16-bit PCM 오디오 데이터
  /// [sampleRate]: 샘플레이트 (16kHz 권장)
  /// Returns: 128x128 Float32 배열 (row-major)
  Future<Float32List> process(Uint8List audioData, int sampleRate) async {
    await initialize();

    debugPrint('[AudioPreprocessor] Processing ${audioData.length} bytes...');
    final stopwatch = Stopwatch()..start();

    // 1. 16-bit PCM → Float32 변환 (-1.0 ~ 1.0)
    final samples = _pcmToFloat(audioData);
    debugPrint('[AudioPreprocessor] Converted to ${samples.length} samples');

    // 2. 리샘플링 (필요시)
    final resampledSamples = sampleRate != targetSampleRate
        ? _resample(samples, sampleRate, targetSampleRate)
        : samples;

    // 3. Pre-emphasis (고주파 강조)
    final emphasized = _preEmphasis(resampledSamples);

    // 4. STFT (Short-Time Fourier Transform)
    final spectrogram = _computeStft(emphasized);

    // 5. Mel Spectrogram 변환
    final melSpectrogram = _applyMelFilterbank(spectrogram);

    // 6. Log-Mel Spectrogram (dB 스케일)
    final logMelSpectrogram = _toLogScale(melSpectrogram);

    // 7. 정규화 (0 ~ 1)
    final normalized = _normalize(logMelSpectrogram);

    // 8. 크기 조정 (128x128)
    final resized = _resizeTo128x128(normalized);

    stopwatch.stop();
    debugPrint(
        '[AudioPreprocessor] Done in ${stopwatch.elapsedMilliseconds}ms');

    return resized;
  }

  /// 16-bit PCM → Float32 변환
  Float32List _pcmToFloat(Uint8List pcmData) {
    final sampleCount = pcmData.length ~/ 2;
    final floatSamples = Float32List(sampleCount);

    for (int i = 0; i < sampleCount; i++) {
      // Little-endian 16-bit signed
      final low = pcmData[i * 2];
      final high = pcmData[i * 2 + 1];
      int sample = (high << 8) | low;

      // Signed 변환
      if (sample >= 32768) sample -= 65536;

      // -1.0 ~ 1.0 정규화
      floatSamples[i] = sample / 32768.0;
    }

    return floatSamples;
  }

  /// 간단한 리샘플링 (선형 보간)
  Float32List _resample(Float32List samples, int fromRate, int toRate) {
    final ratio = toRate / fromRate;
    final newLength = (samples.length * ratio).round();
    final resampled = Float32List(newLength);

    for (int i = 0; i < newLength; i++) {
      final srcIndex = i / ratio;
      final srcIndexInt = srcIndex.floor();
      final frac = srcIndex - srcIndexInt;

      if (srcIndexInt + 1 < samples.length) {
        resampled[i] = samples[srcIndexInt] * (1 - frac) +
            samples[srcIndexInt + 1] * frac;
      } else {
        resampled[i] = samples[srcIndexInt.clamp(0, samples.length - 1)];
      }
    }

    return resampled;
  }

  /// Pre-emphasis 필터 (고주파 강조)
  Float32List _preEmphasis(Float32List samples, [double coeff = 0.97]) {
    final emphasized = Float32List(samples.length);
    emphasized[0] = samples[0];

    for (int i = 1; i < samples.length; i++) {
      emphasized[i] = samples[i] - coeff * samples[i - 1];
    }

    return emphasized;
  }

  /// STFT 계산
  List<Float32List> _computeStft(Float32List samples) {
    final numFrames = (samples.length - nFft) ~/ hopLength + 1;
    final spectrogram = <Float32List>[];

    for (int i = 0; i < numFrames; i++) {
      final start = i * hopLength;
      final frame = Float32List(nFft);

      // 프레임 추출 + 윈도우 적용
      for (int j = 0; j < nFft; j++) {
        if (start + j < samples.length) {
          frame[j] = samples[start + j] * _hannWindow![j];
        } else {
          frame[j] = 0.0;
        }
      }

      // FFT → Power Spectrum
      final powerSpectrum = _computePowerSpectrum(frame);
      spectrogram.add(powerSpectrum);
    }

    return spectrogram;
  }

  /// Power Spectrum 계산 (간단한 DFT 구현)
  Float32List _computePowerSpectrum(Float32List frame) {
    final n = frame.length;
    final halfN = n ~/ 2 + 1;
    final powerSpectrum = Float32List(halfN);

    // 간단한 DFT (실제 구현 시 FFT 라이브러리 사용 권장)
    for (int k = 0; k < halfN; k++) {
      double real = 0.0;
      double imag = 0.0;

      for (int t = 0; t < n; t++) {
        final angle = -2 * math.pi * k * t / n;
        real += frame[t] * math.cos(angle);
        imag += frame[t] * math.sin(angle);
      }

      powerSpectrum[k] = (real * real + imag * imag) / n;
    }

    return powerSpectrum;
  }

  /// Mel 필터뱅크 적용
  List<Float32List> _applyMelFilterbank(List<Float32List> spectrogram) {
    final melSpectrogram = <Float32List>[];
    final freqBins = spectrogram.isNotEmpty ? spectrogram[0].length : 0;

    for (final frame in spectrogram) {
      final melFrame = Float32List(nMels);

      for (int m = 0; m < nMels; m++) {
        double sum = 0.0;
        final filterStart = m * freqBins;

        for (int k = 0; k < freqBins; k++) {
          final filterIdx = filterStart + k;
          if (filterIdx < _melFilterbank!.length) {
            sum += frame[k] * _melFilterbank![filterIdx];
          }
        }

        melFrame[m] = sum;
      }

      melSpectrogram.add(melFrame);
    }

    return melSpectrogram;
  }

  /// Log 스케일 변환
  List<Float32List> _toLogScale(List<Float32List> melSpectrogram) {
    const double eps = 1e-10;
    final logMel = <Float32List>[];

    for (final frame in melSpectrogram) {
      final logFrame = Float32List(frame.length);

      for (int i = 0; i < frame.length; i++) {
        logFrame[i] = 10 * math.log(frame[i] + eps) / math.ln10;
      }

      logMel.add(logFrame);
    }

    return logMel;
  }

  /// 정규화 (0 ~ 1)
  List<Float32List> _normalize(List<Float32List> spectrogram) {
    // Min/Max 찾기
    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;

    for (final frame in spectrogram) {
      for (final val in frame) {
        if (val < minVal) minVal = val;
        if (val > maxVal) maxVal = val;
      }
    }

    // 정규화
    final range = maxVal - minVal;
    if (range < 1e-10) {
      // 상수 신호인 경우
      return spectrogram
          .map((f) => Float32List(f.length)..fillRange(0, f.length, 0.5))
          .toList();
    }

    final normalized = <Float32List>[];
    for (final frame in spectrogram) {
      final normFrame = Float32List(frame.length);
      for (int i = 0; i < frame.length; i++) {
        normFrame[i] = (frame[i] - minVal) / range;
      }
      normalized.add(normFrame);
    }

    return normalized;
  }

  /// 128x128 크기로 조정
  Float32List _resizeTo128x128(List<Float32List> spectrogram) {
    final result = Float32List(targetFrames * nMels);

    if (spectrogram.isEmpty) {
      return result; // 빈 배열 반환
    }

    final srcFrames = spectrogram.length;

    for (int t = 0; t < targetFrames; t++) {
      // 시간 축 보간
      final srcT = t * srcFrames / targetFrames;
      final srcTInt = srcT.floor().clamp(0, srcFrames - 1);
      final frac = srcT - srcTInt;

      final srcFrame1 = spectrogram[srcTInt];
      final srcFrame2 = spectrogram[(srcTInt + 1).clamp(0, srcFrames - 1)];

      for (int m = 0; m < nMels; m++) {
        // 선형 보간
        final val = srcFrame1[m] * (1 - frac) + srcFrame2[m] * frac;
        result[t * nMels + m] = val.clamp(0.0, 1.0);
      }
    }

    return result;
  }

  /// Hann 윈도우 생성
  Float32List _createHannWindow(int size) {
    final window = Float32List(size);
    for (int i = 0; i < size; i++) {
      window[i] = 0.5 * (1 - math.cos(2 * math.pi * i / (size - 1)));
    }
    return window;
  }

  /// Mel 필터뱅크 생성
  Float32List _createMelFilterbank() {
    final freqBins = nFft ~/ 2 + 1;
    final filterbank = Float32List(nMels * freqBins);

    // Hz → Mel 변환
    double hzToMel(double hz) => 2595 * math.log(1 + hz / 700) / math.ln10;
    double melToHz(double mel) => 700 * (math.pow(10, mel / 2595) - 1);

    final melMin = hzToMel(fMin);
    final melMax = hzToMel(fMax);

    // Mel 스케일 포인트
    final melPoints = Float32List(nMels + 2);
    for (int i = 0; i < nMels + 2; i++) {
      melPoints[i] = melMin + (melMax - melMin) * i / (nMels + 1);
    }

    // Hz/bin 변환
    final hzPoints = melPoints.map((m) => melToHz(m)).toList();
    final binPoints = hzPoints
        .map((hz) => ((nFft + 1) * hz / targetSampleRate).floor())
        .toList();

    // 삼각 필터 생성
    for (int m = 0; m < nMels; m++) {
      for (int k = 0; k < freqBins; k++) {
        double weight = 0.0;

        if (k >= binPoints[m] && k <= binPoints[m + 1]) {
          // 상승 슬로프
          if (binPoints[m + 1] != binPoints[m]) {
            weight = (k - binPoints[m]) / (binPoints[m + 1] - binPoints[m]);
          }
        } else if (k >= binPoints[m + 1] && k <= binPoints[m + 2]) {
          // 하강 슬로프
          if (binPoints[m + 2] != binPoints[m + 1]) {
            weight =
                (binPoints[m + 2] - k) / (binPoints[m + 2] - binPoints[m + 1]);
          }
        }

        filterbank[m * freqBins + k] = weight;
      }
    }

    return filterbank;
  }

  /// 리소스 해제
  void dispose() {
    _melFilterbank = null;
    _hannWindow = null;
  }
}
