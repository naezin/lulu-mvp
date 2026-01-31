import 'package:flutter/material.dart';
import '../../../core/design_system/lulu_icons.dart';

/// Fenton 성장 차트 데이터 모델
///
/// 출처: Fenton TR, Kim JH. 2013
/// 적용 범위: 22-50주 (조산아)
class FentonData {
  final String source;
  final String gender;
  final List<FentonWeekData> weeks;

  const FentonData({
    required this.source,
    required this.gender,
    required this.weeks,
  });

  factory FentonData.fromJson(Map<String, dynamic> json) {
    return FentonData(
      source: json['source'] as String,
      gender: json['gender'] as String,
      weeks: (json['weeks'] as List<dynamic>)
          .map((e) => FentonWeekData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 특정 주수의 데이터 조회
  FentonWeekData? getWeekData(int week) {
    try {
      return weeks.firstWhere((w) => w.week == week);
    } catch (_) {
      return null;
    }
  }

  /// 백분위수 계산 (선형 보간)
  double? calculatePercentile({
    required int week,
    required double value,
    required GrowthMetric metric,
  }) {
    final weekData = getWeekData(week);
    if (weekData == null) return null;

    final percentiles = weekData.getPercentileData(metric);
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

class FentonWeekData {
  final int week;
  final PercentileData weight;
  final PercentileData length;
  final PercentileData headCircumference;

  const FentonWeekData({
    required this.week,
    required this.weight,
    required this.length,
    required this.headCircumference,
  });

  factory FentonWeekData.fromJson(Map<String, dynamic> json) {
    return FentonWeekData(
      week: json['week'] as int,
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

class PercentileData {
  final double p3;
  final double p10;
  final double p50;
  final double p90;
  final double p97;

  const PercentileData({
    required this.p3,
    required this.p10,
    required this.p50,
    required this.p90,
    required this.p97,
  });

  factory PercentileData.fromJson(Map<String, dynamic> json) {
    return PercentileData(
      p3: (json['p3'] as num).toDouble(),
      p10: (json['p10'] as num).toDouble(),
      p50: (json['p50'] as num).toDouble(),
      p90: (json['p90'] as num).toDouble(),
      p97: (json['p97'] as num).toDouble(),
    );
  }

  List<double> get allPercentiles => [p3, p10, p50, p90, p97];
}

enum GrowthMetric {
  weight,
  length,
  headCircumference,
}

extension GrowthMetricExtension on GrowthMetric {
  String get label => switch (this) {
        GrowthMetric.weight => '체중',
        GrowthMetric.length => '신장',
        GrowthMetric.headCircumference => '두위',
      };

  String get unit => switch (this) {
        GrowthMetric.weight => 'kg',
        GrowthMetric.length => 'cm',
        GrowthMetric.headCircumference => 'cm',
      };

  IconData get icon => switch (this) {
        GrowthMetric.weight => LuluIcons.weight,
        GrowthMetric.length => LuluIcons.ruler,
        GrowthMetric.headCircumference => LuluIcons.head,
      };
}
