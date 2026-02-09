import 'package:flutter/material.dart';

import 'baby_type.dart';
import '../../core/utils/corrected_age_calculator.dart';
import '../../core/utils/sga_calculator.dart';

/// 아기 모델 - MVP-F 다태아 지원 확장
///
/// 다태아 중심 설계: familyId로 가족과 연결, 교정연령 개별 계산
class BabyModel {
  final String id;
  final String familyId;
  final String name;
  final DateTime birthDate;
  final Gender gender;
  final int? gestationalWeeksAtBirth;
  final int? birthWeightGrams;

  // 다태아 정보
  final BabyType? multipleBirthType;
  final Zygosity? zygosity;
  final int? birthOrder;

  // 메타데이터
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BabyModel({
    required this.id,
    required this.familyId,
    required this.name,
    required this.birthDate,
    this.gender = Gender.unknown,
    this.gestationalWeeksAtBirth,
    this.birthWeightGrams,
    this.multipleBirthType,
    this.zygosity,
    this.birthOrder,
    required this.createdAt,
    this.updatedAt,
  });

  // ========================================
  // 조산아 관련 Getters
  // ========================================

  /// 조산아 여부 (37주 미만)
  bool get isPreterm =>
      gestationalWeeksAtBirth != null && gestationalWeeksAtBirth! < 37;

  /// 만삭아 여부 (37주 이상)
  bool get isFullTerm => !isPreterm;

  /// 교정연령 (주 단위) - 개별 계산
  int? get correctedAgeInWeeks {
    if (!isPreterm || gestationalWeeksAtBirth == null) return null;
    return CorrectedAgeCalculator.calculateInWeeks(
      birthDate: birthDate,
      gestationalWeeksAtBirth: gestationalWeeksAtBirth!,
    );
  }

  /// 교정연령 (월 단위) - 개별 계산
  int? get correctedAgeInMonths {
    if (!isPreterm || gestationalWeeksAtBirth == null) return null;
    return CorrectedAgeCalculator.calculateInMonths(
      birthDate: birthDate,
      gestationalWeeksAtBirth: gestationalWeeksAtBirth!,
    );
  }

  /// 교정연령 (일 단위) - 통계 화면용
  int? get correctedAgeInDays {
    if (!isPreterm || gestationalWeeksAtBirth == null) return null;
    final weeks = correctedAgeInWeeks;
    if (weeks == null) return null;
    return weeks * 7;
  }

  /// 실제 연령 (주 단위)
  int get actualAgeInWeeks {
    return DateTime.now().difference(birthDate).inDays ~/ 7;
  }

  /// 실제 연령 (월 단위)
  int get actualAgeInMonths {
    return DateTime.now().difference(birthDate).inDays ~/ 30;
  }

  /// 적용할 연령 (교정 또는 실제)
  int get effectiveAgeInMonths {
    return correctedAgeInMonths ?? actualAgeInMonths;
  }

  /// 권장 성장 차트 타입 (Fenton vs WHO)
  GrowthChartType get recommendedGrowthChart {
    if (!isPreterm || gestationalWeeksAtBirth == null) {
      return GrowthChartType.who;
    }
    return CorrectedAgeCalculator.selectGrowthChart(
      gestationalWeeksAtBirth: gestationalWeeksAtBirth!,
      correctedAgeInWeeks: correctedAgeInWeeks ?? 0,
    );
  }

  // ========================================
  // SGA-01: 만삭 저체중아 관련 Getters
  // ========================================

  /// SGA(만삭 저체중아) 여부
  bool get isSGA => SGACalculator.isSGA(
        gestationalWeeks: gestationalWeeksAtBirth,
        birthWeightGrams: birthWeightGrams,
      );

  /// 출생 분류 (조산, SGA, 정상)
  BirthClassification get birthClassification =>
      SGACalculator.getBirthClassification(
        gestationalWeeks: gestationalWeeksAtBirth,
        birthWeightGrams: birthWeightGrams,
      );

  /// 교정연령 필요 여부
  bool get needsCorrectedAge => isPreterm;

  /// 홈 화면 상태 뱃지 텍스트
  String? get statusBadgeText => SGACalculator.getStatusBadgeText(
        classification: birthClassification,
        birthDate: birthDate,
        gestationalWeeks: gestationalWeeksAtBirth,
      );

  /// 상태 뱃지 색상
  Color? get statusBadgeColor =>
      SGACalculator.getStatusBadgeColor(birthClassification);

  // ========================================
  // 다태아 관련 Getters
  // ========================================

  /// 다태아 여부
  bool get isMultipleBirth =>
      multipleBirthType != null &&
      multipleBirthType != BabyType.singleton;

  /// 첫째 여부
  bool get isFirstBorn => birthOrder == 1;

  // ========================================
  // JSON 변환
  // ========================================

  /// 로컬 저장소용 (camelCase)
  factory BabyModel.fromJson(Map<String, dynamic> json) {
    return BabyModel(
      id: json['id'] as String? ?? '',
      familyId: json['familyId'] as String? ?? '',
      name: json['name'] as String? ?? 'Baby',
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : DateTime.now(),
      gender: json['gender'] != null
          ? Gender.fromValue(json['gender'] as String)
          : Gender.unknown,
      gestationalWeeksAtBirth: json['gestationalWeeksAtBirth'] as int?,
      birthWeightGrams: json['birthWeightGrams'] as int?,
      multipleBirthType: json['multipleBirthType'] != null
          ? BabyType.fromValue(json['multipleBirthType'] as String)
          : null,
      zygosity: json['zygosity'] != null
          ? Zygosity.fromValue(json['zygosity'] as String)
          : null,
      birthOrder: json['birthOrder'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// 🆕 Supabase용 null 안전 팩토리 (snake_case)
  /// DB에서 null 값이 와도 크래시 없이 기본값 적용
  factory BabyModel.fromSupabase(Map<String, dynamic> json) {
    return BabyModel(
      id: json['id'] as String? ?? '',
      familyId: json['family_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Baby',
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : DateTime.now(),
      gender: _parseGender(json['gender']),
      // 🔴 핵심: null이면 40 (만삭 기본값)
      gestationalWeeksAtBirth: json['gestational_weeks_at_birth'] as int? ??
                               json['gestational_age_weeks'] as int?,
      // 🔴 핵심: null이면 3000 (정상 체중 기본값)
      birthWeightGrams: json['birth_weight_grams'] as int?,
      multipleBirthType: json['multiple_birth_type'] != null
          ? BabyType.fromValue(json['multiple_birth_type'] as String)
          : null,
      zygosity: json['zygosity'] != null
          ? Zygosity.fromValue(json['zygosity'] as String)
          : null,
      birthOrder: json['birth_order'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Gender 파싱 헬퍼 (null 안전)
  static Gender _parseGender(dynamic value) {
    if (value == null) return Gender.unknown;
    if (value is String) {
      try {
        return Gender.fromValue(value);
      } catch (_) {
        return Gender.unknown;
      }
    }
    return Gender.unknown;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender.value,
      if (gestationalWeeksAtBirth != null)
        'gestationalWeeksAtBirth': gestationalWeeksAtBirth,
      if (birthWeightGrams != null) 'birthWeightGrams': birthWeightGrams,
      if (multipleBirthType != null)
        'multipleBirthType': multipleBirthType!.value,
      if (zygosity != null) 'zygosity': zygosity!.value,
      if (birthOrder != null) 'birthOrder': birthOrder,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  // ========================================
  // 복사 (불변성 유지)
  // ========================================

  BabyModel copyWith({
    String? id,
    String? familyId,
    String? name,
    DateTime? birthDate,
    Gender? gender,
    int? gestationalWeeksAtBirth,
    int? birthWeightGrams,
    BabyType? multipleBirthType,
    Zygosity? zygosity,
    int? birthOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BabyModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      gestationalWeeksAtBirth:
          gestationalWeeksAtBirth ?? this.gestationalWeeksAtBirth,
      birthWeightGrams: birthWeightGrams ?? this.birthWeightGrams,
      multipleBirthType: multipleBirthType ?? this.multipleBirthType,
      zygosity: zygosity ?? this.zygosity,
      birthOrder: birthOrder ?? this.birthOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BabyModel &&
        other.id == id &&
        other.familyId == familyId &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, familyId, name);

  @override
  String toString() {
    return 'BabyModel(id: $id, name: $name, isPreterm: $isPreterm, '
        'isMultipleBirth: $isMultipleBirth, birthOrder: $birthOrder)';
  }
}
