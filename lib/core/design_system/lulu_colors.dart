import 'package:flutter/material.dart';

/// Lulu Design System - Colors
///
/// Midnight Blue 다크 테마 기반 컬러 시스템
/// MVP-F: 다태아 구분 색상 추가

class LuluColors {
  // ========================================
  // Background Gradient (Midnight Blue Palette)
  // ========================================

  /// 가장 어두운 배경 (Scaffold)
  static const Color midnightNavy = Color(0xFF0D1B2A);

  /// 카드 배경
  static const Color deepBlue = Color(0xFF1B263B);

  /// Secondary 요소
  static const Color softBlue = Color(0xFF415A77);

  // ========================================
  // Brand Accent Colors
  // ========================================

  /// Primary Accent (라벤더 미스트)
  static const Color lavenderMist = Color(0xFF9D8CD6);

  /// Lighter Accent
  static const Color lavenderGlow = Color(0xFFB4A5E6);

  /// Logo Color (달빛 - Champagne Gold)
  static const Color champagneGold = Color(0xFFD4AF6A);

  // ========================================
  // Surface Colors
  // ========================================

  /// Scaffold 배경
  static const Color surfaceDark = Color(0xFF0D1B2A);

  /// Card 배경
  static const Color surfaceCard = Color(0xFF1B263B);

  /// Elevated 요소 (TextField, Chip 등)
  static const Color surfaceElevated = Color(0xFF2A3F5F);

  // ========================================
  // Logo Colors
  // ========================================

  /// 로고 배경 (Deep Midnight)
  static const Color logoBackground = Color(0xFF0D1321);

  /// 로고 전경 (Champagne Gold)
  static const Color logoForeground = Color(0xFFD4AF6A);

  // ========================================
  // Glassmorphism
  // ========================================

  /// Glassmorphism Border
  static const Color glassBorder = Color(0x1AFFFFFF);

  /// Glassmorphism Background
  static Color glassBackground = Colors.white.withValues(alpha: 0.08);

  // ========================================
  // MVP-F: 다태아 구분 색상 (Baby Colors)
  // ========================================

  /// 첫째 아기 - 하늘색
  static const Color baby1Color = Color(0xFF7EB8DA);

  /// 둘째 아기 - 분홍색
  static const Color baby2Color = Color(0xFFE8B4CB);

  /// 셋째 아기 - 민트색
  static const Color baby3Color = Color(0xFFA8D5BA);

  /// 넷째 아기 - 살구색
  static const Color baby4Color = Color(0xFFF5D6A8);

  /// 아기 색상 리스트
  static const List<Color> babyColors = [
    baby1Color,
    baby2Color,
    baby3Color,
    baby4Color,
  ];

  /// 인덱스로 아기 색상 가져오기
  static Color getBabyColor(int index) {
    if (index < 0 || index >= babyColors.length) {
      return lavenderMist;
    }
    return babyColors[index];
  }

  /// 인덱스로 아기 배경 색상 가져오기 (10% opacity)
  static Color getBabyColorBg(int index) {
    return getBabyColor(index).withValues(alpha: 0.1);
  }
}

/// Text Colors (텍스트 컬러)
class LuluTextColors {
  /// 100% - 제목, 중요 텍스트
  static const Color primary = Color(0xFFE9ECEF);

  /// 70% - 본문, 설명
  static const Color secondary = Color(0xFFADB5BD);

  /// 50% - 힌트, 비활성
  static const Color tertiary = Color(0xFF6C757D);

  /// 30% - 비활성 요소
  static const Color disabled = Color(0xFF495057);
}

/// Activity Colors (활동별 컬러)
class LuluActivityColors {
  /// 수면 - Soft Purple
  static const Color sleep = Color(0xFF9575CD);

  /// 수유 - Soft Orange
  static const Color feeding = Color(0xFFFFB74D);

  /// 기저귀 - Soft Blue
  static const Color diaper = Color(0xFF4FC3F7);

  /// 놀이 - Soft Green
  static const Color play = Color(0xFF81C784);

  /// 건강 - Soft Red
  static const Color health = Color(0xFFE57373);

  // ========================================
  // Background Colors (10% opacity)
  // ========================================

  static Color get sleepBg => sleep.withValues(alpha: 0.1);
  static Color get feedingBg => feeding.withValues(alpha: 0.1);
  static Color get diaperBg => diaper.withValues(alpha: 0.1);
  static Color get playBg => play.withValues(alpha: 0.1);
  static Color get healthBg => health.withValues(alpha: 0.1);

  /// 활동 타입으로 색상 가져오기
  static Color forType(String type) {
    switch (type.toLowerCase()) {
      case 'sleep':
        return sleep;
      case 'feeding':
        return feeding;
      case 'diaper':
        return diaper;
      case 'play':
        return play;
      case 'health':
      case 'temperature':
      case 'medication':
        return health;
      default:
        return LuluColors.lavenderMist;
    }
  }

  /// 활동 타입으로 배경 색상 가져오기
  static Color forTypeBg(String type) {
    return forType(type).withValues(alpha: 0.1);
  }
}

/// Status Colors (상태 컬러)
class LuluStatusColors {
  /// 성공, 완료
  static const Color success = Color(0xFF5FB37B);

  /// 경고, 주의
  static const Color warning = Color(0xFFE8B87E);

  /// 주의 (경고보다 심각)
  static const Color caution = Color(0xFFE87878);

  /// 오류, 긴급
  static const Color error = Color(0xFFE87878);

  /// 정보
  static const Color info = Color(0xFF7BB8E8);

  // ========================================
  // Sweet Spot Gauge (Legacy - 하위 호환용)
  // ========================================

  /// 최적 시간 (Green)
  static const Color optimal = Color(0xFF5FB37B);

  /// 접근 중 (Yellow)
  static const Color approaching = Color(0xFFE8B87E);

  /// 과로 상태 (Red)
  static const Color overtired = Color(0xFFE87878);

  // ========================================
  // Emergency Mode
  // ========================================

  static const Color emergencyRed = Color(0xFFFF6B6B);
  static const Color emergencyBg = Color(0xFF2D1F1F);

  // ========================================
  // Soft Background for Status
  // ========================================

  static Color get successSoft => success.withValues(alpha: 0.15);
  static Color get warningSoft => warning.withValues(alpha: 0.15);
  static Color get errorSoft => error.withValues(alpha: 0.15);
  static Color get infoSoft => info.withValues(alpha: 0.15);
}

/// Sweet Spot Colors (단일 색상 시스템)
///
/// 작업 지시서 v1.2: 모든 Sweet Spot 상태에서 동일한 색상 사용
/// 판단/경고 색상 제거 → Lavender Mist 단일 색상
class LuluSweetSpotColors {
  /// 모든 상태에서 사용하는 단일 색상 (Lavender Mist)
  static const Color neutral = LuluColors.lavenderMist;

  /// 배경색 (10% opacity)
  static Color get neutralBg => neutral.withValues(alpha: 0.1);

  /// 아이콘 색상 (동일)
  static const Color icon = LuluColors.lavenderMist;

  /// 텍스트 색상 (primary text)
  static const Color text = LuluTextColors.primary;

  /// 서브텍스트 색상 (secondary text)
  static const Color subtext = LuluTextColors.secondary;
}
