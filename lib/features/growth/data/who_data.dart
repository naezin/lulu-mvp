import 'fenton_data.dart';

/// WHO 성장 차트 데이터 모델
///
/// 출처: WHO Child Growth Standards. 2006
/// 적용 범위: 0-24개월 (만삭아)
class WHOData {
  final String source;
  final String gender;
  final List<WHOMonthData> months;

  const WHOData({
    required this.source,
    required this.gender,
    required this.months,
  });

  factory WHOData.fromJson(Map<String, dynamic> json) {
    return WHOData(
      source: json['source'] as String,
      gender: json['gender'] as String,
      months: (json['months'] as List<dynamic>)
          .map((e) => WHOMonthData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 특정 개월의 데이터 조회
  WHOMonthData? getMonthData(int month) {
    try {
      return months.firstWhere((m) => m.month == month);
    } catch (_) {
      return null;
    }
  }

  /// 백분위수 계산 (선형 보간)
  double? calculatePercentile({
    required int month,
    required double value,
    required GrowthMetric metric,
  }) {
    final monthData = getMonthData(month);
    if (monthData == null) return null;

    final percentiles = monthData.getPercentileData(metric);
    if (percentiles == null) return null;

    // 범위 밖 체크
    if (value <= percentiles.p3) return 3.0;
    if (value >= percentiles.p97) return 97.0;

    // 선형 보간
    final thresholds = [
      (3, percentiles.p3),
      (10, percentiles.p10),
      (50, percentiles.p50),
      (90, percentiles.p90),
      (97, percentiles.p97),
    ];

    for (int i = 0; i < thresholds.length - 1; i++) {
      final (lowerP, lowerV) = thresholds[i];
      final (upperP, upperV) = thresholds[i + 1];

      if (value >= lowerV && value <= upperV) {
        final ratio = (value - lowerV) / (upperV - lowerV);
        return lowerP + ratio * (upperP - lowerP);
      }
    }

    return 50.0; // 기본값
  }
}

class WHOMonthData {
  final int month;
  final PercentileData weight;
  final PercentileData length;
  final PercentileData headCircumference;

  const WHOMonthData({
    required this.month,
    required this.weight,
    required this.length,
    required this.headCircumference,
  });

  factory WHOMonthData.fromJson(Map<String, dynamic> json) {
    return WHOMonthData(
      month: json['month'] as int,
      weight: PercentileData.fromJson(json['weight'] as Map<String, dynamic>),
      length: PercentileData.fromJson(json['length'] as Map<String, dynamic>),
      headCircumference: PercentileData.fromJson(
          json['headCircumference'] as Map<String, dynamic>),
    );
  }

  PercentileData? getPercentileData(GrowthMetric metric) {
    return switch (metric) {
      GrowthMetric.weight => weight,
      GrowthMetric.length => length,
      GrowthMetric.headCircumference => headCircumference,
    };
  }
}
