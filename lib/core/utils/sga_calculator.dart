import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart' show S;
import '../design_system/lulu_colors.dart';

/// SGA (Small for Gestational Age) 판별 유틸리티
/// 출처: Fenton 2013 + WHO growth standards 참조
///
/// SGA 정의: 만삭(37주 이상) 출생아 중 출생체중이 해당 주수의 10th percentile 미만
class SGACalculator {
  SGACalculator._();

  /// 만삭아 10th percentile 체중 기준 (g)
  /// 출처: WHO growth standards
  static const Map<int, int> tenthPercentileWeight = {
    37: 2500,
    38: 2600,
    39: 2700,
    40: 2800,
    41: 2900,
    42: 2950,
  };

  /// SGA 여부 판별
  /// - 조산아(37주 미만)는 SGA 대상 아님 (별도 관리)
  /// - 만삭아 중 10th percentile 미만만 SGA
  static bool isSGA({
    required int? gestationalWeeks,
    required int? birthWeightGrams,
  }) {
    // 데이터 부족 시 false
    if (gestationalWeeks == null || birthWeightGrams == null) return false;

    // 조산아는 SGA 판별 대상 아님
    if (gestationalWeeks < 37) return false;

    final threshold = getThreshold(gestationalWeeks);
    return birthWeightGrams < threshold;
  }

  /// 출생 유형 분류
  static BirthClassification getBirthClassification({
    required int? gestationalWeeks,
    required int? birthWeightGrams,
  }) {
    // 재태주수 정보 없으면 만삭 정상체중으로 간주
    if (gestationalWeeks == null) return BirthClassification.fullTermAGA;

    if (gestationalWeeks < 37) return BirthClassification.preterm;

    if (isSGA(
      gestationalWeeks: gestationalWeeks,
      birthWeightGrams: birthWeightGrams,
    )) {
      return BirthClassification.fullTermSGA;
    }

    return BirthClassification.fullTermAGA;
  }

  /// 10th percentile 기준값 조회
  static int getThreshold(int gestationalWeeks) {
    if (gestationalWeeks < 37) return 0; // 조산아는 해당 없음
    return tenthPercentileWeight[gestationalWeeks] ??
        tenthPercentileWeight[42]!;
  }

  /// 상태 뱃지 텍스트 가져오기
  static String? getStatusBadgeText({
    required BirthClassification classification,
    required DateTime birthDate,
    required int? gestationalWeeks,
    S? l10n,
  }) {
    switch (classification) {
      case BirthClassification.preterm:
        // 교정연령 표시
        if (gestationalWeeks == null) return null;
        final fullTermWeeks = 40;
        final weeksDiff = fullTermWeeks - gestationalWeeks;
        final today = DateTime.now();
        final actualDays = today.difference(birthDate).inDays;
        final correctedDays = actualDays - (weeksDiff * 7);

        if (correctedDays < 0) {
          return l10n?.sgaCorrectedAgeDMinus(correctedDays) ??
              'D$correctedDays';
        }
        return l10n?.sgaCorrectedAgeDPlus(correctedDays) ??
            'D+$correctedDays';

      case BirthClassification.fullTermSGA:
        return l10n?.sgaGrowthTrackingMode ?? 'Growth tracking mode';

      case BirthClassification.fullTermAGA:
        return null; // No badge
    }
  }

  /// 상태 뱃지 색상 가져오기
  static Color? getStatusBadgeColor(BirthClassification classification) {
    switch (classification) {
      case BirthClassification.preterm:
        return LuluColors.midnightNavy;
      case BirthClassification.fullTermSGA:
        return const Color(0xFF00897B); // Teal
      case BirthClassification.fullTermAGA:
        return null;
    }
  }
}

/// 출생 유형 분류
enum BirthClassification {
  /// 조산아 (37주 미만)
  preterm,

  /// 만삭 저체중 (SGA)
  fullTermSGA,

  /// 만삭 정상체중
  fullTermAGA,
}
