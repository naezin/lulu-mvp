import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// 울음 분류 타입 (Dunstan Baby Language 기반)
///
/// Phase 2: AI 울음 분석 기능
/// 5가지 기본 울음 + Unknown (분류 불가)
enum CryType {
  /// 배고픔 (Neh) - 빨기 반사로 인한 울음
  hungry('hungry', 'Neh'),

  /// 졸림 (Owh) - 하품과 함께 나는 울음
  tired('tired', 'Owh'),

  /// 불편함 (Heh) - 신체적 불편함 (기저귀, 체온 등)
  discomfort('discomfort', 'Heh'),

  /// 가스/복통 (Eairh) - 배에 가스가 찼을 때
  gas('gas', 'Eairh'),

  /// 트림 필요 (Eh) - 트림이 필요할 때
  burp('burp', 'Eh'),

  /// 분류 불가 - 울음이 아니거나 명확하지 않음
  unknown('unknown', '-');

  const CryType(this.value, this.dunstanCode);

  /// JSON/DB 저장용 값
  final String value;

  /// Dunstan Baby Language 코드
  final String dunstanCode;

  /// 값으로부터 CryType 생성
  static CryType fromValue(String value) {
    return CryType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CryType.unknown,
    );
  }

  /// 지역화된 라벨 (S l10n 필요)
  String localizedLabel(S? l10n) {
    switch (this) {
      case CryType.hungry:
        return l10n?.cryTypeHungry ?? 'Hungry';
      case CryType.tired:
        return l10n?.cryTypeTired ?? 'Tired';
      case CryType.discomfort:
        return l10n?.cryTypeDiscomfort ?? 'Uncomfortable';
      case CryType.gas:
        return l10n?.cryTypeGas ?? 'Gas / Colic';
      case CryType.burp:
        return l10n?.cryTypeBurp ?? 'Needs Burping';
      case CryType.unknown:
        return l10n?.cryTypeUnknown ?? 'Analyzing...';
    }
  }

  /// 라벨 (하위 호환용 - 기본값은 영어)
  String get label => localizedLabel(null);

  /// 지역화된 상세 설명 (부모 가이드)
  String localizedDescription(S? l10n) {
    switch (this) {
      case CryType.hungry:
        return l10n?.cryDescHungry ?? 'Baby cries from hunger.\nOften accompanied by opening mouth or sucking on hands.';
      case CryType.tired:
        return l10n?.cryDescTired ?? 'Baby cries from being tired.\nOften accompanied by yawning or rubbing eyes.';
      case CryType.discomfort:
        return l10n?.cryDescDiscomfort ?? 'Baby cries from physical discomfort.\nMay need a diaper change, or feel too hot or cold.';
      case CryType.gas:
        return l10n?.cryDescGas ?? 'Baby cries from gas in the tummy.\nOften pulls legs toward the belly.';
      case CryType.burp:
        return l10n?.cryDescBurp ?? 'Baby cries when needing to burp.\nCommon after feeding.';
      case CryType.unknown:
        return l10n?.cryDescUnknown ?? 'Analyzing the cry pattern.\nA clearer cry sound is needed.';
    }
  }

  /// 상세 설명 (하위 호환용 - 기본값은 영어)
  String get description => localizedDescription(null);

  /// 지역화된 권장 행동
  String localizedSuggestedAction(S? l10n) {
    switch (this) {
      case CryType.hungry:
        return l10n?.cryActionHungry ?? 'Try starting a feeding';
      case CryType.tired:
        return l10n?.cryActionTired ?? 'Try putting baby to sleep';
      case CryType.discomfort:
        return l10n?.cryActionDiscomfort ?? 'Check diaper and clothing';
      case CryType.gas:
        return l10n?.cryActionGas ?? "Gently massage baby's tummy";
      case CryType.burp:
        return l10n?.cryActionBurp ?? "Pat baby's back to help burp";
      case CryType.unknown:
        return l10n?.cryActionUnknown ?? 'Try analyzing again';
    }
  }

  /// 권장 행동 (하위 호환용 - 기본값은 영어)
  String get suggestedAction => localizedSuggestedAction(null);

  /// 아이콘
  IconData get icon {
    switch (this) {
      case CryType.hungry:
        return LuluIcons.restaurantOutlined;
      case CryType.tired:
        return LuluIcons.sleepOutlined;
      case CryType.discomfort:
        return LuluIcons.sentimentSadOutlined;
      case CryType.gas:
        return LuluIcons.cough;
      case CryType.burp:
        return LuluIcons.bubbleChart;
      case CryType.unknown:
        return LuluIcons.helpOutline;
    }
  }

  /// 색상
  Color get color {
    switch (this) {
      case CryType.hungry:
        return LuluActivityColors.feeding;
      case CryType.tired:
        return LuluActivityColors.sleep;
      case CryType.discomfort:
        return LuluActivityColors.diaper;
      case CryType.gas:
        return LuluStatusColors.warning;
      case CryType.burp:
        return LuluActivityColors.health;
      case CryType.unknown:
        return LuluTextColors.tertiary;
    }
  }

  /// 배경 색상 (10% opacity)
  Color get backgroundColor => color.withValues(alpha: 0.1);

  /// 관련 활동 기록 타입
  String? get relatedActivityType {
    switch (this) {
      case CryType.hungry:
        return 'feeding';
      case CryType.tired:
        return 'sleep';
      case CryType.discomfort:
        return 'diaper';
      case CryType.gas:
      case CryType.burp:
        return 'health';
      case CryType.unknown:
        return null;
    }
  }
}
