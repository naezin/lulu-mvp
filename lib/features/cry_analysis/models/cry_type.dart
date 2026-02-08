import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';

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

  /// 한국어 라벨
  String get label {
    switch (this) {
      case CryType.hungry:
        return '배고파요';
      case CryType.tired:
        return '졸려요';
      case CryType.discomfort:
        return '불편해요';
      case CryType.gas:
        return '배가 아파요';
      case CryType.burp:
        return '트림이 필요해요';
      case CryType.unknown:
        return '분석 중...';
    }
  }

  /// 영어 라벨
  String get labelEn {
    switch (this) {
      case CryType.hungry:
        return 'Hungry';
      case CryType.tired:
        return 'Tired';
      case CryType.discomfort:
        return 'Uncomfortable';
      case CryType.gas:
        return 'Gas / Colic';
      case CryType.burp:
        return 'Needs Burping';
      case CryType.unknown:
        return 'Analyzing...';
    }
  }

  /// 상세 설명 (부모 가이드)
  String get description {
    switch (this) {
      case CryType.hungry:
        return '아기가 배고플 때 내는 울음이에요.\n입을 벌리거나 손을 빠는 행동과 함께 나타나요.';
      case CryType.tired:
        return '아기가 졸리고 피곤할 때 내는 울음이에요.\n하품을 하거나 눈을 비비는 신호와 함께 나타나요.';
      case CryType.discomfort:
        return '아기가 신체적으로 불편할 때 내는 울음이에요.\n기저귀가 젖었거나, 덥거나 추울 수 있어요.';
      case CryType.gas:
        return '아기 배에 가스가 찼을 때 내는 울음이에요.\n다리를 배 쪽으로 끌어당기는 동작을 해요.';
      case CryType.burp:
        return '아기가 트림을 하고 싶을 때 내는 울음이에요.\n수유 후에 자주 나타나요.';
      case CryType.unknown:
        return '울음 패턴을 분석 중이에요.\n좀 더 명확한 울음 소리가 필요해요.';
    }
  }

  /// 권장 행동
  String get suggestedAction {
    switch (this) {
      case CryType.hungry:
        return '수유를 시작해보세요';
      case CryType.tired:
        return '재우기를 시도해보세요';
      case CryType.discomfort:
        return '기저귀와 옷을 확인해보세요';
      case CryType.gas:
        return '배를 부드럽게 마사지해보세요';
      case CryType.burp:
        return '등을 토닥이며 트림시켜주세요';
      case CryType.unknown:
        return '다시 분석해보세요';
    }
  }

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
