import 'package:flutter/material.dart';

/// Lulu Design System - Border Radius
///
/// 일관된 라운드 코너 시스템

class LuluRadius {
  /// 2px - 타임바, 차트 미니 바
  static const double xxs = 2;

  /// 3px - 차트 bar radius
  static const double bar = 3;

  /// 4px - 프로그레스바, 인디케이터
  static const double indicator = 4;

  /// 8px - 작은 버튼, 칩
  static const double xs = 8;

  /// 10px - 설정 화면 섹션 카드
  static const double section = 10;

  /// 12px - 입력 필드
  static const double sm = 12;

  /// 16px - 버튼
  static const double md = 16;

  /// 20px - 카드
  static const double lg = 20;

  /// 24px - 큰 카드
  static const double xl = 24;

  /// 28px - Bottom Sheet
  static const double xxl = 28;

  /// 999px - 원형
  static const double full = 999;

  // ========================================
  // BorderRadius Presets
  // ========================================

  /// 카드 (20px)
  static final BorderRadius card = BorderRadius.circular(lg);

  /// 버튼 (16px)
  static final BorderRadius button = BorderRadius.circular(md);

  /// 입력 필드 (12px)
  static final BorderRadius input = BorderRadius.circular(sm);

  /// 칩 (8px)
  static final BorderRadius chip = BorderRadius.circular(xs);

  /// Bottom Sheet (상단만 28px)
  static const BorderRadius bottomSheet = BorderRadius.vertical(
    top: Radius.circular(xxl),
  );

  /// 원형
  static final BorderRadius circular = BorderRadius.circular(full);

  // ========================================
  // RoundedRectangleBorder Presets
  // ========================================

  /// 카드 Shape
  static final RoundedRectangleBorder cardShape = RoundedRectangleBorder(
    borderRadius: card,
  );

  /// 버튼 Shape
  static final RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
    borderRadius: button,
  );

  /// 입력 필드 Shape
  static final RoundedRectangleBorder inputShape = RoundedRectangleBorder(
    borderRadius: input,
  );

  /// Bottom Sheet Shape
  static const RoundedRectangleBorder bottomSheetShape =
      RoundedRectangleBorder(
    borderRadius: bottomSheet,
  );
}
