// 수유 타입 정의 (v2.0)
//
// MVP-F Sprint 8: 수유 기록 화면 리디자인
// - 모유 > 직접/유축 분리
// - 이유식 상세 기록 (SolidFoodUnit, BabyReaction)
// - 기존 데이터 하위 호환성 유지

import 'package:flutter/material.dart' show Color, IconData, Icons;
import '../../core/design_system/lulu_icons.dart';

/// 수유 내용물 타입 (What)
enum FeedingContentType {
  breastMilk, // 모유 (직접 또는 유축)
  formula, // 분유
  solid, // 이유식
}

/// 수유 방법 타입 (How) - 모유일 때만 사용
enum FeedingMethodType {
  direct, // 직접 수유
  expressed, // 유축 젖병
}

/// 직접 수유 시 좌/우
enum BreastSide {
  left,
  right,
  both,
}

/// 사용자 수유 방식 설정 (온보딩에서 선택) - Phase B
enum FeedingPreference {
  exclusiveBreastfeeding, // 완전 모유수유 (EBF)
  exclusiveFormula, // 완전 분유수유 (EFF)
  mixedFeeding, // 혼합 수유 (MF)
}

/// 이유식 양 단위
enum SolidFoodUnit {
  gram, // g
  spoon, // 숟가락
  bowl, // 그릇
}

/// 아기 반응
enum BabyReaction {
  liked, // 잘 먹음
  neutral, // 보통
  rejected, // 거부
}

/// FeedingContentType 확장
extension FeedingContentTypeExtension on FeedingContentType {
  /// 표시용 라벨
  String get label {
    switch (this) {
      case FeedingContentType.breastMilk:
        return '모유';
      case FeedingContentType.formula:
        return '분유';
      case FeedingContentType.solid:
        return '이유식';
    }
  }

  /// 서브 라벨 (모유만)
  String? get subLabel {
    switch (this) {
      case FeedingContentType.breastMilk:
        return '(직접/유축)';
      case FeedingContentType.formula:
      case FeedingContentType.solid:
        return null;
    }
  }

  /// 기존 feeding_type 값으로 변환 (하위 호환성)
  String get legacyValue {
    switch (this) {
      case FeedingContentType.breastMilk:
        return 'breast'; // 기존 breast 유지
      case FeedingContentType.formula:
        return 'formula';
      case FeedingContentType.solid:
        return 'solid';
    }
  }
}

/// FeedingMethodType 확장
extension FeedingMethodTypeExtension on FeedingMethodType {
  /// 표시용 라벨
  String get label {
    switch (this) {
      case FeedingMethodType.direct:
        return '직접 수유';
      case FeedingMethodType.expressed:
        return '유축 젖병';
    }
  }
}

/// BreastSide 확장
extension BreastSideExtension on BreastSide {
  /// 표시용 라벨
  String get label {
    switch (this) {
      case BreastSide.left:
        return '왼쪽';
      case BreastSide.right:
        return '오른쪽';
      case BreastSide.both:
        return '양쪽';
    }
  }

  /// 짧은 라벨
  String get shortLabel {
    switch (this) {
      case BreastSide.left:
        return 'L';
      case BreastSide.right:
        return 'R';
      case BreastSide.both:
        return '양쪽';
    }
  }

  /// 값으로 변환
  String get value {
    switch (this) {
      case BreastSide.left:
        return 'left';
      case BreastSide.right:
        return 'right';
      case BreastSide.both:
        return 'both';
    }
  }

  /// 값에서 생성
  static BreastSide? fromValue(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'left':
        return BreastSide.left;
      case 'right':
        return BreastSide.right;
      case 'both':
        return BreastSide.both;
      default:
        return null;
    }
  }
}

/// 기존 타입에서 신규 타입으로 변환 (마이그레이션용)
extension FeedingTypeMigration on String {
  /// 기존 feeding_type → FeedingContentType
  FeedingContentType toContentType() {
    switch (toLowerCase()) {
      case 'breast':
        return FeedingContentType.breastMilk;
      case 'bottle':
        return FeedingContentType.breastMilk; // 젖병=유축으로 간주
      case 'formula':
        return FeedingContentType.formula;
      case 'solid':
        return FeedingContentType.solid;
      default:
        return FeedingContentType.formula;
    }
  }

  /// 기존 feeding_type → FeedingMethodType
  FeedingMethodType? toMethodType() {
    switch (toLowerCase()) {
      case 'breast':
        return FeedingMethodType.direct;
      case 'bottle':
        return FeedingMethodType.expressed;
      default:
        return null;
    }
  }
}

/// SolidFoodUnit 확장
extension SolidFoodUnitExtension on SolidFoodUnit {
  /// 표시용 라벨 (한국어)
  String get label {
    switch (this) {
      case SolidFoodUnit.gram:
        return 'g';
      case SolidFoodUnit.spoon:
        return '숟가락';
      case SolidFoodUnit.bowl:
        return '그릇';
    }
  }

  /// 표시용 라벨 (영어)
  String get labelEn {
    switch (this) {
      case SolidFoodUnit.gram:
        return 'g';
      case SolidFoodUnit.spoon:
        return 'spoon';
      case SolidFoodUnit.bowl:
        return 'bowl';
    }
  }

  /// 양 조절 단위 (step)
  int get step {
    switch (this) {
      case SolidFoodUnit.gram:
        return 10; // 10g 단위
      case SolidFoodUnit.spoon:
        return 1; // 1숟가락 단위
      case SolidFoodUnit.bowl:
        return 1; // 1그릇 단위
    }
  }

  /// 저장용 값
  String get value => name;

  /// 값에서 생성
  static SolidFoodUnit? fromValue(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'gram':
        return SolidFoodUnit.gram;
      case 'spoon':
        return SolidFoodUnit.spoon;
      case 'bowl':
        return SolidFoodUnit.bowl;
      default:
        return null;
    }
  }
}

/// BabyReaction 확장
extension BabyReactionExtension on BabyReaction {
  /// 표시용 라벨 (한국어)
  String get label {
    switch (this) {
      case BabyReaction.liked:
        return '잘 먹음';
      case BabyReaction.neutral:
        return '보통';
      case BabyReaction.rejected:
        return '거부';
    }
  }

  /// 표시용 라벨 (영어)
  String get labelEn {
    switch (this) {
      case BabyReaction.liked:
        return 'Liked';
      case BabyReaction.neutral:
        return 'Neutral';
      case BabyReaction.rejected:
        return 'Rejected';
    }
  }

  /// 아이콘 (Material Icons)
  IconData get icon {
    switch (this) {
      case BabyReaction.liked:
        return LuluIcons.sentimentHappy;
      case BabyReaction.neutral:
        return LuluIcons.sentimentNeutral;
      case BabyReaction.rejected:
        return LuluIcons.sentimentSad;
    }
  }

  /// 색상 (LuluStatusColors 사용)
  Color get color {
    switch (this) {
      case BabyReaction.liked:
        return const Color(0xFF5FB37B); // LuluStatusColors.success
      case BabyReaction.neutral:
        return const Color(0xFF9D8CD6); // LuluColors.lavenderMist
      case BabyReaction.rejected:
        return const Color(0xFFE8B87E); // LuluStatusColors.warning
    }
  }

  /// 저장용 값
  String get value => name;

  /// 값에서 생성
  static BabyReaction? fromValue(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'liked':
        return BabyReaction.liked;
      case 'neutral':
        return BabyReaction.neutral;
      case 'rejected':
        return BabyReaction.rejected;
      default:
        return null;
    }
  }
}

/// FeedingContentType 파싱
extension FeedingContentTypeParsing on String {
  /// 문자열에서 FeedingContentType으로 변환
  FeedingContentType? toFeedingContentType() {
    switch (toLowerCase()) {
      case 'breastmilk':
        return FeedingContentType.breastMilk;
      case 'formula':
        return FeedingContentType.formula;
      case 'solid':
        return FeedingContentType.solid;
      default:
        return null;
    }
  }
}

/// FeedingMethodType 파싱
extension FeedingMethodTypeParsing on String {
  /// 문자열에서 FeedingMethodType으로 변환
  FeedingMethodType? toFeedingMethodType() {
    switch (toLowerCase()) {
      case 'direct':
        return FeedingMethodType.direct;
      case 'expressed':
        return FeedingMethodType.expressed;
      default:
        return null;
    }
  }
}
