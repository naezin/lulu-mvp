/// 성장 측정값 유효성 검사
///
/// 스펙 v1.1 기준:
/// - 체중: 0.3 - 30.0 kg (필수)
/// - 신장: 20.0 - 120.0 cm (선택)
/// - 두위: 15.0 - 60.0 cm (선택)
class GrowthInputValidator {
  GrowthInputValidator._();

  /// 체중 검사
  static String? validateWeight(double? value, {required bool isRequired}) {
    if (isRequired && value == null) {
      return '체중을 입력해주세요';
    }
    if (value != null) {
      if (value < 0.3) {
        return '체중이 너무 작습니다 (최소 0.3kg)';
      }
      if (value > 30.0) {
        return '체중이 너무 큽니다 (최대 30kg)';
      }
    }
    return null;
  }

  /// 신장 검사
  static String? validateLength(double? value) {
    if (value == null) return null; // 선택 필드
    if (value < 20.0) {
      return '신장이 너무 작습니다 (최소 20cm)';
    }
    if (value > 120.0) {
      return '신장이 너무 큽니다 (최대 120cm)';
    }
    return null;
  }

  /// 두위 검사
  static String? validateHeadCircumference(double? value) {
    if (value == null) return null; // 선택 필드
    if (value < 15.0) {
      return '두위가 너무 작습니다 (최소 15cm)';
    }
    if (value > 60.0) {
      return '두위가 너무 큽니다 (최대 60cm)';
    }
    return null;
  }

  /// 측정일 검사
  static String? validateMeasuredAt(
    DateTime? value, {
    required DateTime birthDate,
  }) {
    if (value == null) {
      return '측정일을 선택해주세요';
    }
    if (value.isBefore(birthDate)) {
      return '측정일은 출생일 이후여야 합니다';
    }
    if (value.isAfter(DateTime.now())) {
      return '미래 날짜는 선택할 수 없습니다';
    }
    return null;
  }

  /// 급격한 변화 경고 (에러 아님, 경고만)
  static String? checkRapidWeightChange(
    double? current,
    double? previous,
    int daysDiff,
  ) {
    if (current == null || previous == null || daysDiff <= 0) {
      return null;
    }

    final dailyChangeGrams = ((current - previous) * 1000).abs() / daysDiff;

    // 하루 50g 이상 변화 시 경고
    if (dailyChangeGrams > 50) {
      return '급격한 변화가 감지되었어요. 입력값을 확인해주세요.';
    }
    return null;
  }

  /// 급격한 신장 변화 경고
  static String? checkRapidLengthChange(
    double? current,
    double? previous,
    int daysDiff,
  ) {
    if (current == null || previous == null || daysDiff <= 0) {
      return null;
    }

    final dailyChangeCm = (current - previous).abs() / daysDiff;

    // 하루 0.3cm 이상 변화 시 경고 (비현실적)
    if (dailyChangeCm > 0.3) {
      return '급격한 신장 변화가 감지되었어요. 입력값을 확인해주세요.';
    }
    return null;
  }

  /// 전체 폼 유효성 검사
  static GrowthValidationResult validateForm({
    required double? weight,
    double? length,
    double? headCircumference,
    required DateTime? measuredAt,
    required DateTime birthDate,
    double? previousWeight,
    double? previousLength,
    DateTime? previousDate,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // 필수 필드 검사
    final weightError = validateWeight(weight, isRequired: true);
    if (weightError != null) errors.add(weightError);

    final dateError = validateMeasuredAt(measuredAt, birthDate: birthDate);
    if (dateError != null) errors.add(dateError);

    // 선택 필드 검사
    final lengthError = validateLength(length);
    if (lengthError != null) errors.add(lengthError);

    final headCircError = validateHeadCircumference(headCircumference);
    if (headCircError != null) errors.add(headCircError);

    // 급격한 변화 경고
    if (previousDate != null) {
      final daysDiff = measuredAt?.difference(previousDate).inDays ?? 0;

      final weightWarning = checkRapidWeightChange(
        weight,
        previousWeight,
        daysDiff,
      );
      if (weightWarning != null) warnings.add(weightWarning);

      final lengthWarning = checkRapidLengthChange(
        length,
        previousLength,
        daysDiff,
      );
      if (lengthWarning != null) warnings.add(lengthWarning);
    }

    return GrowthValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
}

/// 유효성 검사 결과
class GrowthValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const GrowthValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
}
