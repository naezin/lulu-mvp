import '../../data/models/baby_type.dart';
import '../../l10n/generated/app_localizations.dart' show S;

/// 교정연령 계산기 - Neonatology Specialist 검증 필수
///
/// 조산아의 교정연령을 계산하고 적절한 성장 차트를 선택합니다.
/// 교정연령 = 실제연령 - (40주 - 출생주수)
///
/// 적용 범위:
/// - 성장 차트: 만 2세까지
/// - 발달 마일스톤: 만 2세까지
/// - Sweet Spot: 만 1세까지
class CorrectedAgeCalculator {
  /// 만삭 기준 주수
  static const int fullTermWeeks = 40;

  /// 조산 기준 주수 (37주 미만)
  static const int pretermThreshold = 37;

  /// Fenton 차트에서 WHO 차트로 전환하는 총 주수
  static const int fentonToWhoTransitionWeeks = 50;

  /// 교정연령 적용 최대 나이 (2년 = 104주)
  static const int maxCorrectionWeeks = 104;

  // ========================================
  // 교정연령 계산
  // ========================================

  /// 교정연령 계산 (주 단위)
  ///
  /// [birthDate] 출생일
  /// [gestationalWeeksAtBirth] 출생 시 임신 주수
  /// [currentDate] 현재 날짜 (테스트용, 기본값: DateTime.now())
  ///
  /// Returns: 교정연령 (주), 음수일 경우 0 반환
  static int calculateInWeeks({
    required DateTime birthDate,
    required int gestationalWeeksAtBirth,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    final actualAgeInDays = now.difference(birthDate).inDays;

    // 만삭아는 교정 불필요
    if (gestationalWeeksAtBirth >= pretermThreshold) {
      return (actualAgeInDays / 7).floor();
    }

    // 교정 계산: 실제연령 - (40주 - 출생주수)
    final pretermWeeks = fullTermWeeks - gestationalWeeksAtBirth;
    final correctionDays = pretermWeeks * 7;
    final correctedAgeInDays = actualAgeInDays - correctionDays;

    // 음수 방지, 최대 2년까지만 교정 적용
    return correctedAgeInDays.clamp(0, maxCorrectionWeeks * 7) ~/ 7;
  }

  /// 교정연령 계산 (월 단위)
  ///
  /// 주 단위를 월 단위로 변환 (4주 = 1개월)
  static int calculateInMonths({
    required DateTime birthDate,
    required int gestationalWeeksAtBirth,
    DateTime? currentDate,
  }) {
    final weeks = calculateInWeeks(
      birthDate: birthDate,
      gestationalWeeksAtBirth: gestationalWeeksAtBirth,
      currentDate: currentDate,
    );
    return (weeks / 4).floor();
  }

  /// 교정연령 계산 (일 단위)
  static int calculateInDays({
    required DateTime birthDate,
    required int gestationalWeeksAtBirth,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    final actualAgeInDays = now.difference(birthDate).inDays;

    if (gestationalWeeksAtBirth >= pretermThreshold) {
      return actualAgeInDays;
    }

    final pretermWeeks = fullTermWeeks - gestationalWeeksAtBirth;
    final correctionDays = pretermWeeks * 7;
    final correctedAgeInDays = actualAgeInDays - correctionDays;

    return correctedAgeInDays.clamp(0, maxCorrectionWeeks * 7);
  }

  // ========================================
  // 성장 차트 선택
  // ========================================

  /// Fenton vs WHO 차트 선택
  ///
  /// - 만삭아: WHO 차트
  /// - 조산아 (총 주수 < 50주): Fenton 차트
  /// - 조산아 (총 주수 >= 50주): WHO 차트
  ///
  /// 총 주수 = 출생 주수 + 교정연령 주수
  static GrowthChartType selectGrowthChart({
    required int gestationalWeeksAtBirth,
    required int correctedAgeInWeeks,
  }) {
    // 만삭아는 항상 WHO
    if (gestationalWeeksAtBirth >= pretermThreshold) {
      return GrowthChartType.who;
    }

    // 총 주수 계산
    final totalWeeks = gestationalWeeksAtBirth + correctedAgeInWeeks;

    // 50주 미만: Fenton, 50주 이상: WHO
    return totalWeeks < fentonToWhoTransitionWeeks
        ? GrowthChartType.fenton
        : GrowthChartType.who;
  }

  // ========================================
  // 헬퍼 메서드
  // ========================================

  /// 조산아 여부 확인
  static bool isPreterm(int gestationalWeeksAtBirth) {
    return gestationalWeeksAtBirth < pretermThreshold;
  }

  /// 교정연령 적용 가능 여부 (2세 이하)
  static bool shouldApplyCorrection({
    required DateTime birthDate,
    required int gestationalWeeksAtBirth,
    DateTime? currentDate,
  }) {
    if (!isPreterm(gestationalWeeksAtBirth)) return false;

    final now = currentDate ?? DateTime.now();
    final actualAgeInWeeks = now.difference(birthDate).inDays ~/ 7;

    return actualAgeInWeeks <= maxCorrectionWeeks;
  }

  /// 교정연령 문자열 포맷
  /// 예: "3개월 2주" 또는 "교정 3개월 2주"
  static String formatCorrectedAge({
    required S l10n,
    required int correctedAgeInWeeks,
    bool includePrefix = true,
  }) {
    final months = correctedAgeInWeeks ~/ 4;
    final weeks = correctedAgeInWeeks % 4;

    final prefix = includePrefix ? l10n.correctedAgeFormatPrefix : '';

    if (months == 0) {
      return l10n.correctedAgeFormatWeeksOnly(prefix, weeks);
    } else if (weeks == 0) {
      return l10n.correctedAgeFormatMonthsOnly(prefix, months);
    } else {
      return l10n.correctedAgeFormatMonthsWeeks(prefix, months, weeks);
    }
  }

  /// 실제연령 문자열 포맷
  static String formatActualAge({
    required S l10n,
    required int actualAgeInWeeks,
  }) {
    final months = actualAgeInWeeks ~/ 4;
    final weeks = actualAgeInWeeks % 4;

    if (months == 0) {
      return l10n.actualAgeFormatWeeksOnly(weeks);
    } else if (weeks == 0) {
      return l10n.actualAgeFormatMonthsOnly(months);
    } else {
      return l10n.actualAgeFormatMonthsWeeks(months, weeks);
    }
  }
}
