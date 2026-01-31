import 'package:flutter/foundation.dart';

import '../../../data/models/models.dart';
import '../data/fenton_data.dart';
import '../data/growth_data_cache.dart' hide Gender, GrowthChartType;

/// 성장 화면 상태 관리 Provider
///
/// 다태아 지원:
/// - 선택된 아기별 데이터 관리
/// - 개별 교정연령 기준 차트 유형 결정
class GrowthProvider extends ChangeNotifier {
  List<BabyModel> _babies = [];
  String? _selectedBabyId;
  List<GrowthMeasurementModel> _measurements = [];
  GrowthScreenState _state = GrowthScreenState.loading;
  String? _errorMessage;
  int _retryCount = 0;

  // Getters
  List<BabyModel> get babies => _babies;
  String? get selectedBabyId => _selectedBabyId;
  GrowthScreenState get state => _state;
  String? get errorMessage => _errorMessage;

  /// 선택된 아기
  BabyModel? get selectedBaby {
    if (_selectedBabyId == null) return _babies.firstOrNull;
    return _babies.where((b) => b.id == _selectedBabyId).firstOrNull;
  }

  /// 선택된 아기의 측정 기록 (최신순)
  List<GrowthMeasurementModel> get measurements {
    final baby = selectedBaby;
    if (baby == null) return [];
    return _measurements
        .where((m) => m.babyId == baby.id)
        .toList()
      ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
  }

  /// 최신 측정 기록
  GrowthMeasurementModel? get latestMeasurement => measurements.firstOrNull;

  /// 이전 측정 기록
  GrowthMeasurementModel? get previousMeasurement {
    if (measurements.length < 2) return null;
    return measurements[1];
  }

  /// 차트 유형 (Fenton vs WHO)
  GrowthChartType get chartType {
    final baby = selectedBaby;
    if (baby == null) return GrowthChartType.who;

    return GrowthDataCache.instance.determineChartType(
      gestationalWeeks: baby.gestationalWeeksAtBirth,
      birthDate: baby.birthDate,
    );
  }

  /// 현재 교정 주수 (Fenton용)
  int? get correctedWeeks {
    final baby = selectedBaby;
    if (baby == null) return null;
    if (!baby.isPreterm) return null;

    final actualDays = DateTime.now().difference(baby.birthDate).inDays;
    final actualWeeks = actualDays ~/ 7;
    return (baby.gestationalWeeksAtBirth ?? 40) + actualWeeks;
  }

  /// 현재 교정 개월수 (WHO용)
  int get correctedMonths {
    final baby = selectedBaby;
    if (baby == null) return 0;

    if (baby.isPreterm && baby.gestationalWeeksAtBirth != null) {
      // 교정연령 계산
      final actualDays = DateTime.now().difference(baby.birthDate).inDays;
      final correctionDays = (40 - baby.gestationalWeeksAtBirth!) * 7;
      return ((actualDays - correctionDays) / 30.44).floor().clamp(0, 24);
    } else {
      // 만삭아: 실제 연령
      return (DateTime.now().difference(baby.birthDate).inDays / 30.44)
          .floor()
          .clamp(0, 24);
    }
  }

  /// 성별 (차트용)
  Gender get gender {
    final baby = selectedBaby;
    if (baby == null) return Gender.male;
    return baby.gender == Gender.unknown ? Gender.male : baby.gender;
  }

  /// 백분위수 계산 결과
  GrowthPercentiles? get percentiles {
    final measurement = latestMeasurement;
    if (measurement == null) return null;

    final cache = GrowthDataCache.instance;
    final weekOrMonth =
        chartType == GrowthChartType.fenton ? correctedWeeks ?? 40 : correctedMonths;

    return GrowthPercentiles(
      weight: cache.calculatePercentile(
        gender: gender,
        chartType: chartType,
        metric: GrowthMetric.weight,
        value: measurement.weightKg,
        weekOrMonth: weekOrMonth,
      ),
      length: measurement.lengthCm != null
          ? cache.calculatePercentile(
              gender: gender,
              chartType: chartType,
              metric: GrowthMetric.length,
              value: measurement.lengthCm!,
              weekOrMonth: weekOrMonth,
            )
          : null,
      headCircumference: measurement.headCircumferenceCm != null
          ? cache.calculatePercentile(
              gender: gender,
              chartType: chartType,
              metric: GrowthMetric.headCircumference,
              value: measurement.headCircumferenceCm!,
              weekOrMonth: weekOrMonth,
            )
          : null,
    );
  }

  /// 초기화
  Future<void> initialize(List<BabyModel> babies) async {
    _babies = babies;
    if (babies.isNotEmpty) {
      _selectedBabyId = babies.first.id;
    }
    await loadMeasurements();
  }

  /// 아기 선택
  void selectBaby(String? babyId) {
    _selectedBabyId = babyId;
    notifyListeners();
  }

  /// 측정 기록 로드
  Future<void> loadMeasurements() async {
    _state = GrowthScreenState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: 실제 데이터 로드 구현 (SharedPreferences + Firebase)
      await Future.delayed(const Duration(milliseconds: 300));

      // 저장된 데이터가 없으면 empty 상태 (하드코딩 테스트 데이터 제거)
      // _measurements는 addMeasurement()로만 추가됨

      if (_measurements.isEmpty) {
        _state = GrowthScreenState.empty;
      } else {
        _state = GrowthScreenState.loaded;
      }
      _retryCount = 0;
    } catch (e) {
      _retryCount++;
      _errorMessage = _getErrorMessage(e);
      _state = GrowthScreenState.error;
    }

    notifyListeners();
  }

  /// 재시도
  Future<void> retry() async {
    if (_retryCount >= 3) {
      _errorMessage = '잠시 후 다시 시도해주세요';
      notifyListeners();
      return;
    }
    await loadMeasurements();
  }

  /// 측정 기록 추가
  Future<void> addMeasurement(GrowthMeasurementModel measurement) async {
    _measurements = [..._measurements, measurement];
    _state = GrowthScreenState.loaded;
    notifyListeners();

    // TODO: 로컬 저장 + 동기화
  }

  /// 측정 기록 삭제
  Future<void> deleteMeasurement(String measurementId) async {
    _measurements = _measurements.where((m) => m.id != measurementId).toList();
    if (_measurements.isEmpty) {
      _state = GrowthScreenState.empty;
    }
    notifyListeners();

    // TODO: 로컬 삭제 + 동기화
  }

  String _getErrorMessage(Object error) {
    // 에러 유형별 메시지
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('network') || errorString.contains('socket')) {
      return '인터넷 연결을 확인해주세요';
    }
    if (errorString.contains('timeout')) {
      return '연결이 느려요. 다시 시도할까요?';
    }
    return '데이터를 불러오지 못했어요';
  }

}

/// 화면 상태
enum GrowthScreenState {
  loading,
  empty,
  error,
  loaded,
}

/// 백분위수 결과
class GrowthPercentiles {
  final double? weight;
  final double? length;
  final double? headCircumference;

  const GrowthPercentiles({
    this.weight,
    this.length,
    this.headCircumference,
  });

  /// 백분위수 해석
  String interpretPercentile(double? percentile) {
    if (percentile == null) return '측정 필요';
    if (percentile < 3) return '3% 미만';
    if (percentile < 10) return '${percentile.round()}%';
    if (percentile <= 90) return '${percentile.round()}%';
    if (percentile <= 97) return '${percentile.round()}%';
    return '97% 초과';
  }

  /// 상태 색상 결정
  PercentileStatus getStatus(double? percentile) {
    if (percentile == null) return PercentileStatus.unknown;
    if (percentile < 3 || percentile > 97) return PercentileStatus.caution;
    if (percentile < 10 || percentile > 90) return PercentileStatus.watch;
    return PercentileStatus.normal;
  }
}

enum PercentileStatus {
  normal,
  watch,
  caution,
  unknown,
}

/// 작업 지시서 v1.2: Huckleberry 스타일 문구
/// "정상/비정상", "양호/관찰/주의" → 부드러운 확률적 표현
extension PercentileStatusExtension on PercentileStatus {
  String get label => switch (this) {
        PercentileStatus.normal => '잘 자라고 있어요',
        PercentileStatus.watch => '지켜봐 주세요',
        PercentileStatus.caution => '소아과 상담을 고려해주세요',
        PercentileStatus.unknown => '측정이 필요해요',
      };
}
