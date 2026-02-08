import 'package:flutter/material.dart';

/// Lulu Design System - Shadows
///
/// 일관된 그림자 시스템

class LuluShadows {
  // ========================================
  // 카드 그림자 (Card Shadows)
  // ========================================

  /// 기본 카드 그림자
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  /// 강조된 카드 그림자
  static List<BoxShadow> cardElevated = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 15,
      offset: const Offset(0, 6),
    ),
  ];

  // ========================================
  // Glassmorphism 그림자
  // ========================================

  static List<BoxShadow> glassmorphism = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  // ========================================
  // FAB 그림자 (Floating Action Button)
  // ========================================

  static List<BoxShadow> fab({Color? color}) {
    return [
      BoxShadow(
        color: (color ?? const Color(0xFF9D8CD6)).withValues(alpha: 0.3),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ];
  }

  // ========================================
  // Bottom Sheet 그림자
  // ========================================

  static List<BoxShadow> bottomSheet = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 24,
      offset: const Offset(0, -4),
    ),
  ];

  // ========================================
  // 작은 그림자 (Subtle)
  // ========================================

  static List<BoxShadow> subtle = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  // ========================================
  // 상단 바 그림자 (Top Bar - 기록 화면)
  // ========================================

  static List<BoxShadow> topBar = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, -2),
    ),
  ];

  // ========================================
  // 버튼 그림자 (Button)
  // ========================================

  static List<BoxShadow> button = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ========================================
  // 떠있는 요소 그림자 (Elevated)
  // ========================================

  static List<BoxShadow> elevated = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  // ========================================
  // 글로우 효과 (Glow - 울음분석 버튼 등)
  // ========================================

  static List<BoxShadow> glow({required Color color}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.3),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }

  // ========================================
  // 바 글로우 효과 (Bar Glow - 차트)
  // ========================================

  static List<BoxShadow> barGlow({required Color color}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.4),
        blurRadius: 8,
      ),
    ];
  }
}
