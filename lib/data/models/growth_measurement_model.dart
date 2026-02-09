import 'package:uuid/uuid.dart';

import '../../l10n/generated/app_localizations.dart' show S;

/// 성장 측정 기록 모델
///
/// 다태아 지원: 아기별 개별 기록
/// 오프라인 지원: 로컬 저장 후 동기화
class GrowthMeasurementModel {
  final String id;
  final String babyId;
  final DateTime measuredAt;
  final double weightKg;
  final double? lengthCm;
  final double? headCircumferenceCm;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const GrowthMeasurementModel({
    required this.id,
    required this.babyId,
    required this.measuredAt,
    required this.weightKg,
    this.lengthCm,
    this.headCircumferenceCm,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  /// 새 측정 기록 생성
  factory GrowthMeasurementModel.create({
    required String babyId,
    required DateTime measuredAt,
    required double weightKg,
    double? lengthCm,
    double? headCircumferenceCm,
    String? note,
  }) {
    final now = DateTime.now();
    return GrowthMeasurementModel(
      id: const Uuid().v4(),
      babyId: babyId,
      measuredAt: measuredAt,
      weightKg: weightKg,
      lengthCm: lengthCm,
      headCircumferenceCm: headCircumferenceCm,
      note: note,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );
  }

  /// JSON 변환
  factory GrowthMeasurementModel.fromJson(Map<String, dynamic> json) {
    return GrowthMeasurementModel(
      id: json['id'] as String,
      babyId: json['babyId'] as String,
      measuredAt: DateTime.parse(json['measuredAt'] as String),
      weightKg: (json['weightKg'] as num).toDouble(),
      lengthCm: json['lengthCm'] != null
          ? (json['lengthCm'] as num).toDouble()
          : null,
      headCircumferenceCm: json['headCircumferenceCm'] != null
          ? (json['headCircumferenceCm'] as num).toDouble()
          : null,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'babyId': babyId,
      'measuredAt': measuredAt.toIso8601String(),
      'weightKg': weightKg,
      'lengthCm': lengthCm,
      'headCircumferenceCm': headCircumferenceCm,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  /// 복사본 생성 (불변성 유지)
  GrowthMeasurementModel copyWith({
    String? id,
    String? babyId,
    DateTime? measuredAt,
    double? weightKg,
    double? lengthCm,
    double? headCircumferenceCm,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return GrowthMeasurementModel(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      measuredAt: measuredAt ?? this.measuredAt,
      weightKg: weightKg ?? this.weightKg,
      lengthCm: lengthCm ?? this.lengthCm,
      headCircumferenceCm: headCircumferenceCm ?? this.headCircumferenceCm,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// 동기화 완료 표시
  GrowthMeasurementModel markSynced() {
    return copyWith(isSynced: true);
  }

  /// 이전 측정과의 변화량 계산
  GrowthChange? calculateChange(GrowthMeasurementModel? previous) {
    if (previous == null) return null;

    final daysDiff = measuredAt.difference(previous.measuredAt).inDays;
    if (daysDiff <= 0) return null;

    return GrowthChange(
      weightChange: weightKg - previous.weightKg,
      lengthChange: lengthCm != null && previous.lengthCm != null
          ? lengthCm! - previous.lengthCm!
          : null,
      headCircumferenceChange:
          headCircumferenceCm != null && previous.headCircumferenceCm != null
              ? headCircumferenceCm! - previous.headCircumferenceCm!
              : null,
      daysDiff: daysDiff,
    );
  }

  @override
  String toString() {
    return 'GrowthMeasurement(id: $id, babyId: $babyId, '
        'weight: ${weightKg}kg, length: ${lengthCm}cm, '
        'headCirc: ${headCircumferenceCm}cm)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GrowthMeasurementModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 성장 변화량
class GrowthChange {
  final double weightChange;
  final double? lengthChange;
  final double? headCircumferenceChange;
  final int daysDiff;

  const GrowthChange({
    required this.weightChange,
    this.lengthChange,
    this.headCircumferenceChange,
    required this.daysDiff,
  });

  /// 일일 체중 변화량 (g/day)
  double get dailyWeightChangeGrams => (weightChange * 1000) / daysDiff;

  /// 급격한 변화 여부 (하루 50g 이상)
  bool get isRapidWeightChange => dailyWeightChangeGrams.abs() > 50;

  /// 변화 방향
  MeasurementDirection get weightDirection {
    if (weightChange > 0.01) return MeasurementDirection.increasing;
    if (weightChange < -0.01) return MeasurementDirection.decreasing;
    return MeasurementDirection.stable;
  }
}

/// 측정값 변화 방향
/// (Flutter의 GrowthDirection과 이름 충돌 방지)
enum MeasurementDirection {
  increasing,
  stable,
  decreasing,
}

extension MeasurementDirectionExtension on MeasurementDirection {
  String localizedLabel(S? l10n) => switch (this) {
        MeasurementDirection.increasing =>
          l10n?.directionIncreasing ?? 'Increasing',
        MeasurementDirection.stable =>
          l10n?.directionStable ?? 'Stable',
        MeasurementDirection.decreasing =>
          l10n?.directionDecreasing ?? 'Decreasing',
      };

  String get label => localizedLabel(null);

  String get emoji => switch (this) {
        MeasurementDirection.increasing => '↑',
        MeasurementDirection.stable => '→',
        MeasurementDirection.decreasing => '↓',
      };
}
