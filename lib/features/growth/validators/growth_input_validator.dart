import '../../../l10n/generated/app_localizations.dart' show S;

/// 성장 측정값 유효성 검사
///
/// 스펙 v1.1 기준:
/// - 체중: 0.3 - 30.0 kg (필수)
/// - 신장: 20.0 - 120.0 cm (선택)
/// - 두위: 15.0 - 60.0 cm (선택)
class GrowthInputValidator {
  GrowthInputValidator._();

  /// 체중 검사
  static String? validateWeight(
    double? value, {
    required bool isRequired,
    required S l10n,
  }) {
    if (isRequired && value == null) {
      return l10n.errorEnterWeight;
    }
    if (value != null) {
      if (value < 0.3) {
        return l10n.errorWeightTooLow;
      }
      if (value > 30.0) {
        return l10n.errorWeightTooHigh;
      }
    }
    return null;
  }

  /// 신장 검사
  static String? validateLength(double? value, {required S l10n}) {
    if (value == null) return null; // 선택 필드
    if (value < 20.0) {
      return l10n.errorLengthTooLow;
    }
    if (value > 120.0) {
      return l10n.errorLengthTooHigh;
    }
    return null;
  }

  /// 두위 검사
  static String? validateHeadCircumference(
    double? value, {
    required S l10n,
  }) {
    if (value == null) return null; // 선택 필드
    if (value < 15.0) {
      return l10n.errorHeadCircTooLow;
    }
    if (value > 60.0) {
      return l10n.errorHeadCircTooHigh;
    }
    return null;
  }

  /// 측정일 검사
  static String? validateMeasuredAt(
    DateTime? value, {
    required DateTime birthDate,
    required S l10n,
  }) {
    if (value == null) {
      return l10n.errorSelectMeasuredDate;
    }
    if (value.isBefore(birthDate)) {
      return l10n.errorMeasuredDateAfterBirth;
    }
    if (value.isAfter(DateTime.now())) {
      return l10n.errorFutureDate;
    }
    return null;
  }

  /// 급격한 변화 경고 (에러 아님, 경고만)
  static String? checkRapidWeightChange(
    double? current,
    double? previous,
    int daysDiff, {
    S? l10n,
  }) {
    if (current == null || previous == null || daysDiff <= 0) {
      return null;
    }

    final dailyChangeGrams = ((current - previous) * 1000).abs() / daysDiff;

    // 하루 50g 이상 변화 시 경고
    if (dailyChangeGrams > 50) {
      return l10n?.warningRapidWeightChange;
    }
    return null;
  }

  /// 급격한 신장 변화 경고
  static String? checkRapidLengthChange(
    double? current,
    double? previous,
    int daysDiff, {
    S? l10n,
  }) {
    if (current == null || previous == null || daysDiff <= 0) {
      return null;
    }

    final dailyChangeCm = (current - previous).abs() / daysDiff;

    // 하루 0.3cm 이상 변화 시 경고 (비현실적)
    if (dailyChangeCm > 0.3) {
      return l10n?.warningRapidLengthChange;
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
    required S l10n,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // 필수 필드 검사
    final weightError = validateWeight(weight, isRequired: true, l10n: l10n);
    if (weightError != null) errors.add(weightError);

    final dateError =
        validateMeasuredAt(measuredAt, birthDate: birthDate, l10n: l10n);
    if (dateError != null) errors.add(dateError);

    // 선택 필드 검사
    final lengthError = validateLength(length, l10n: l10n);
    if (lengthError != null) errors.add(lengthError);

    final headCircError =
        validateHeadCircumference(headCircumference, l10n: l10n);
    if (headCircError != null) errors.add(headCircError);

    // 급격한 변화 경고
    if (previousDate != null) {
      final daysDiff = measuredAt?.difference(previousDate).inDays ?? 0;

      final weightWarning = checkRapidWeightChange(
        weight,
        previousWeight,
        daysDiff,
        l10n: l10n,
      );
      if (weightWarning != null) warnings.add(weightWarning);

      final lengthWarning = checkRapidLengthChange(
        length,
        previousLength,
        daysDiff,
        l10n: l10n,
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
