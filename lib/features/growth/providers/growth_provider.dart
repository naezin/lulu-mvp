import 'package:flutter/foundation.dart';

import '../../../data/models/models.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
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
    if (_selectedBabyId == babyId) return;
    _selectedBabyId = babyId;
    notifyListeners();
  }

  /// 측정 기록 로드
  Future<void> loadMeasurements({S? l10n}) async {
    _state = GrowthScreenState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Replace with DB load when measurements table is created
      // When implementing: fetch DB data FIRST, then check for birth seed
      await Future.delayed(const Duration(milliseconds: 300));

      // A-6: Birth weight auto-seed with date-based dedup
      // Check if birth date measurement already exists (prevents duplicates
      // when DB load is implemented — DB may already contain birth measurement)
      final baby = selectedBaby;
      if (baby != null && baby.birthWeightGrams != null) {
        final hasBirthMeasurement = _measurements.any(
          (m) =>
              m.babyId == baby.id &&
              m.measuredAt.year == baby.birthDate.year &&
              m.measuredAt.month == baby.birthDate.month &&
              m.measuredAt.day == baby.birthDate.day,
        );

        if (!hasBirthMeasurement) {
          final birthMeasurement = GrowthMeasurementModel.create(
            babyId: baby.id,
            measuredAt: baby.birthDate,
            weightKg: baby.birthWeightGrams! / 1000.0,
          );
          _measurements = [..._measurements, birthMeasurement];
        }
      }

      _state = _measurements.isEmpty
          ? GrowthScreenState.empty
          : GrowthScreenState.loaded;
      _retryCount = 0;
    } catch (e) {
      _retryCount++;
      _errorMessage = _getErrorMessage(e, l10n: l10n);
      _state = GrowthScreenState.error;
    }

    notifyListeners();
  }

  /// 재시도
  Future<void> retry({S? l10n}) async {
    if (_retryCount >= 3) {
      _errorMessage = l10n?.errorRetryLater ?? 'Please try again later';
      notifyListeners();
      return;
    }
    await loadMeasurements(l10n: l10n);
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

  String _getErrorMessage(Object error, {S? l10n}) {
    // 에러 유형별 메시지
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('network') || errorString.contains('socket')) {
      return l10n?.errorNetworkCheck ?? 'Please check your internet connection';
    }
    if (errorString.contains('timeout')) {
      return l10n?.errorConnectionSlow ?? 'Connection is slow. Try again?';
    }
    return l10n?.errorDataLoadFailed ?? 'Failed to load data';
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
  String interpretPercentile(double? percentile, {S? l10n}) {
    if (percentile == null) {
      return l10n?.percentileMeasureNeeded ?? 'Measurement needed';
    }
    if (percentile < 3) {
      return l10n?.percentileBelow3 ?? 'Below 3%';
    }
    if (percentile < 10) return '${percentile.round()}%';
    if (percentile <= 90) return '${percentile.round()}%';
    if (percentile <= 97) return '${percentile.round()}%';
    return l10n?.percentileAbove97 ?? 'Above 97%';
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
  /// 다국어 지원 라벨 (S 파라미터 필수)
  String localizedLabel(S l10n) => switch (this) {
        PercentileStatus.normal => l10n.percentileGrowingWell,
        PercentileStatus.watch => l10n.percentileWatchNeeded,
        PercentileStatus.caution => l10n.percentileDoctorConsult,
        PercentileStatus.unknown => l10n.percentileMeasurementNeeded,
      };

  /// 영문 폴백 라벨 (BuildContext 없는 곳에서 사용)
  String get label => switch (this) {
        PercentileStatus.normal => 'Growing well',
        PercentileStatus.watch => 'Keep an eye on it',
        PercentileStatus.caution => 'Consider consulting a pediatrician',
        PercentileStatus.unknown => 'Measurement is needed',
      };
}
