import 'dart:convert';
import 'package:flutter/services.dart';

import '../../../data/models/baby_type.dart';
import 'fenton_data.dart';
import 'who_data.dart';

export '../../../data/models/baby_type.dart' show Gender, GrowthChartType;

/// 성장 차트 데이터 캐시 (싱글톤)
///
/// 앱 시작 시 로컬 JSON 파일을 메모리에 캐시
/// 오프라인에서도 차트 표시 가능 (새벽 3시 시나리오 대응)
class GrowthDataCache {
  static GrowthDataCache? _instance;
  static GrowthDataCache get instance => _instance ??= GrowthDataCache._();

  GrowthDataCache._();

  late final FentonData _fentonBoys;
  late final FentonData _fentonGirls;
  late final WHOData _whoBoys;
  late final WHOData _whoGirls;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// 앱 시작 시 호출 (main.dart)
  Future<void> initialize() async {
    if (_isInitialized) return;

    final futures = await Future.wait([
      rootBundle.loadString('assets/data/fenton_boys.json'),
      rootBundle.loadString('assets/data/fenton_girls.json'),
      rootBundle.loadString('assets/data/who_boys.json'),
      rootBundle.loadString('assets/data/who_girls.json'),
    ]);

    _fentonBoys = FentonData.fromJson(jsonDecode(futures[0]));
    _fentonGirls = FentonData.fromJson(jsonDecode(futures[1]));
    _whoBoys = WHOData.fromJson(jsonDecode(futures[2]));
    _whoGirls = WHOData.fromJson(jsonDecode(futures[3]));

    _isInitialized = true;
  }

  /// Fenton 데이터 조회
  FentonData getFenton(Gender gender) {
    _ensureInitialized();
    return gender == Gender.male ? _fentonBoys : _fentonGirls;
  }

  /// WHO 데이터 조회
  WHOData getWHO(Gender gender) {
    _ensureInitialized();
    return gender == Gender.male ? _whoBoys : _whoGirls;
  }

  /// 차트 유형 결정 (Fenton vs WHO)
  ///
  /// Fenton: 22-50주 (조산아)
  /// WHO: 50주 이후 또는 만삭아
  GrowthChartType determineChartType({
    required int? gestationalWeeks,
    required DateTime birthDate,
  }) {
    // 만삭아 (37주 이상)
    if (gestationalWeeks == null || gestationalWeeks >= 37) {
      return GrowthChartType.who;
    }

    // 조산아: 총 주수 계산
    final actualDays = DateTime.now().difference(birthDate).inDays;
    final actualWeeks = actualDays ~/ 7;
    final totalWeeks = gestationalWeeks + actualWeeks;

    // 50주 미만: Fenton, 50주 이상: WHO
    return totalWeeks < 50 ? GrowthChartType.fenton : GrowthChartType.who;
  }

  /// 백분위수 계산
  double? calculatePercentile({
    required Gender gender,
    required GrowthChartType chartType,
    required GrowthMetric metric,
    required double value,
    required int weekOrMonth,
  }) {
    if (chartType == GrowthChartType.fenton) {
      return getFenton(gender).calculatePercentile(
        week: weekOrMonth,
        value: value,
        metric: metric,
      );
    } else {
      return getWHO(gender).calculatePercentile(
        month: weekOrMonth,
        value: value,
        metric: metric,
      );
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'GrowthDataCache not initialized. Call initialize() first.',
      );
    }
  }
}

extension GrowthChartTypeDescriptionExtension on GrowthChartType {
  String get description => switch (this) {
        GrowthChartType.fenton => '조산아 성장 차트 (22-50주)',
        GrowthChartType.who => '세계보건기구 성장 차트 (0-24개월)',
      };
}
