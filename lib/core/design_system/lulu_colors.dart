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

  /// Deep Indigo (Family Screen 등에서 사용)
  static const Color deepIndigo = Color(0xFF3D4F7F);

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

  // ========================================
  // Sprint 23 C-5: Baby Color Alpha Variants
  // ========================================
  // Sweet Spot 카드 골든 밴드/accent line 용

  // --- Baby 1 (Sky Blue #7EB8DA) ---
  /// baby1 15% — 밴드 배경
  static const Color baby1Light = Color(0x267EB8DA);
  /// baby1 30% — 밴드 경계
  static const Color baby1Border = Color(0x4D7EB8DA);
  /// baby1 80% — 강한 밴드
  static const Color baby1Strong = Color(0xCC7EB8DA);

  // --- Baby 2 (Pink #E8B4CB) ---
  /// baby2 15% — 밴드 배경
  static const Color baby2Light = Color(0x26E8B4CB);
  /// baby2 30% — 밴드 경계
  static const Color baby2Border = Color(0x4DE8B4CB);
  /// baby2 80% — 강한 밴드
  static const Color baby2Strong = Color(0xCCE8B4CB);

  // --- Baby 3 (Mint #A8D5BA) ---
  /// baby3 15% — 밴드 배경
  static const Color baby3Light = Color(0x26A8D5BA);
  /// baby3 30% — 밴드 경계
  static const Color baby3Border = Color(0x4DA8D5BA);
  /// baby3 80% — 강한 밴드
  static const Color baby3Strong = Color(0xCCA8D5BA);

  // --- Baby 4 (Apricot #F5D6A8) ---
  /// baby4 15% — 밴드 배경
  static const Color baby4Light = Color(0x26F5D6A8);
  /// baby4 30% — 밴드 경계
  static const Color baby4Border = Color(0x4DF5D6A8);
  /// baby4 80% — 강한 밴드
  static const Color baby4Strong = Color(0xCCF5D6A8);

  /// 아기별 Light (15%) 토큰 리스트
  static const List<Color> babyColorsLight = [
    baby1Light, baby2Light, baby3Light, baby4Light,
  ];

  /// 아기별 Border (30%) 토큰 리스트
  static const List<Color> babyColorsBorder = [
    baby1Border, baby2Border, baby3Border, baby4Border,
  ];

  /// 아기별 Strong (80%) 토큰 리스트
  static const List<Color> babyColorsStrong = [
    baby1Strong, baby2Strong, baby3Strong, baby4Strong,
  ];

  /// 인덱스로 아기 Light 색상 가져오기 (15%)
  static Color getBabyColorLight(int index) {
    if (index < 0 || index >= babyColorsLight.length) {
      return lavenderLight;
    }
    return babyColorsLight[index];
  }

  /// 인덱스로 아기 Border 색상 가져오기 (30%)
  static Color getBabyColorBorder(int index) {
    if (index < 0 || index >= babyColorsBorder.length) {
      return lavenderBorder;
    }
    return babyColorsBorder[index];
  }

  /// 인덱스로 아기 Strong 색상 가져오기 (80%)
  static Color getBabyColorStrong(int index) {
    if (index < 0 || index >= babyColorsStrong.length) {
      return lavenderStrong;
    }
    return babyColorsStrong[index];
  }

  // ========================================
  // Sprint 19: 차트 솔리드 컬러
  // ========================================

  /// 차트 컨테이너 배경 (lavenderMist 10%)
  static const Color chartContainerBg = Color(0x1A9D8CD6);

  /// 차트 컨테이너 테두리 (lavenderMist 30%)
  static const Color chartContainerBorder = Color(0x4D9D8CD6);

  /// 차트 칩 선택 배경 (lavenderMist 20%)
  static const Color chartChipSelectedBg = Color(0x339D8CD6);

  /// 차트 칩 선택 테두리 (lavenderMist 50%)
  static const Color chartChipSelectedBorder = Color(0x809D8CD6);

  /// 차트 스켈레톤 배경 (= chartContainerBg)
  static const Color chartSkeletonBg = Color(0x1A9D8CD6);

  /// 차트 스켈레톤 테두리 (= chartContainerBorder)
  static const Color chartSkeletonBorder = Color(0x4D9D8CD6);

  /// 네비게이터 버튼 배경 (= chartContainerBg)
  static const Color navButtonBg = Color(0x1A9D8CD6);

  /// 주간 피커 선택 배경 (lavenderMist 15%)
  static const Color weekPickerSelected = Color(0x269D8CD6);

  /// 범례 밤잠 (= nightSleep 솔리드)
  static const Color legendNightSleep = Color(0xFF5B5381);

  /// 범례 낮잠 (= daySleep 솔리드)
  static const Color legendDaySleep = Color(0xFF9D8CD6);

  // ========================================
  // Sprint 19: 필터칩 타입별 선택 배경 (20%)
  // ========================================

  /// 수면 칩 선택 배경
  static const Color chipSleepBg = Color(0x339575CD);

  /// 수면 칩 선택 테두리
  static const Color chipSleepBorder = Color(0x809575CD);

  /// 수유 칩 선택 배경
  static const Color chipFeedingBg = Color(0x33FFB74D);

  /// 수유 칩 선택 테두리
  static const Color chipFeedingBorder = Color(0x80FFB74D);

  /// 기저귀 칩 선택 배경
  static const Color chipDiaperBg = Color(0x334FC3F7);

  /// 기저귀 칩 선택 테두리
  static const Color chipDiaperBorder = Color(0x804FC3F7);

  /// 놀이 칩 선택 배경
  static const Color chipPlayBg = Color(0x3381C784);

  /// 놀이 칩 선택 테두리
  static const Color chipPlayBorder = Color(0x8081C784);

  /// 건강 칩 선택 배경
  static const Color chipHealthBg = Color(0x33E57373);

  /// 건강 칩 선택 테두리
  static const Color chipHealthBorder = Color(0x80E57373);

  // ========================================
  // Sprint 19: 빈 상태 원형 배경 (lavenderMist 20%)
  // ========================================

  /// 빈 상태 원형 배경
  static const Color emptyCircleBg = Color(0x339D8CD6);

  // ========================================
  // Sprint 19: 차트 배경 바 (paint 내부)
  // ========================================

  /// 차트 배경 바
  static const Color chartBarBg = Color(0xFF1E1E3A);

  // ========================================
  // Sprint 19.5: 범용 Alpha 솔리드 컬러
  // ========================================
  // withOpacity/withValues → 솔리드 컬러 마이그레이션
  // 3건+ = 솔리드, 2건 = 솔리드(주석), 1건 = withValues 유지

  // --- Lavender Mist Alpha Variants ---

  /// lavenderMist 10% — 배경, 서브틀
  static const Color lavenderBg = Color(0x1A9D8CD6);

  /// lavenderMist 15% — 라이트 배경
  static const Color lavenderLight = Color(0x269D8CD6);

  /// lavenderMist 20% — 선택 상태
  static const Color lavenderSelected = Color(0x339D8CD6);

  /// lavenderMist 30% — 테두리
  static const Color lavenderBorder = Color(0x4D9D8CD6);

  /// lavenderMist 50% — 중간 강조
  static const Color lavenderMedium = Color(0x809D8CD6);

  // --- Deep Indigo Alpha Variants ---

  /// deepIndigo 30% — 테두리, 구분선
  static const Color deepIndigoBorder = Color(0x4D3D4F7F);

  /// deepIndigo 50% — 중간 배경
  static const Color deepIndigoMedium = Color(0x803D4F7F);

  // --- Surface Elevated Alpha Variants ---

  /// surfaceElevated 50% — 반투명 배경
  static const Color surfaceElevatedMedium = Color(0x802A3F5F);

  // --- Deep Blue Alpha Variants ---

  /// deepBlue alpha 0 — gradient fade-out
  static const Color deepBlueTransparent = Color(0x001B263B);

  /// deepBlue 80% — 진한 오버레이
  static const Color deepBlueStrong = Color(0xCC1B263B); // 2건 사용

  // --- Shadow ---

  /// 검정 30% — 그림자
  static const Color shadowBlack = Color(0x4D000000); // 2건 사용

  // --- Red Alpha Variants ---

  /// Colors.red 10% — 에러 입력 배경
  static const Color redBg = Color(0x1AF44336); // 2건 사용

  // ========================================
  // Sprint 21 Phase 4: 추가 솔리드 토큰
  // ========================================

  // --- Lavender Mist extended ---

  /// lavenderMist 8% — 플레이스홀더 배경
  static const Color lavenderSubtle = Color(0x149D8CD6);

  /// lavenderMist 80% — 강한 강조
  static const Color lavenderStrong = Color(0xCC9D8CD6);

  // --- Deep Blue extended ---

  /// deepBlue 50% — 면책/오버레이 배경
  static const Color deepBlueMedium = Color(0x801B263B);

  // --- Midnight Navy extended ---

  /// midnightNavy 50% — 진행 마커
  static const Color midnightNavyMedium = Color(0x800D1B2A);

  // --- Surface Elevated extended ---

  /// surfaceElevated 30% — 그리드 라인
  static const Color surfaceElevatedBorder = Color(0x4D2A3F5F);

  // --- Champagne Gold extended ---

  /// champagneGold 15% — 뱃지 배경
  static const Color champagneGoldLight = Color(0x26D4AF6A);

  // --- Insight/Tip Colors ---

  /// amberGold base (0xFFFBBF24)
  static const Color amberGold = Color(0xFFFBBF24);

  /// amberGold 10% — 인사이트/팁 배경
  static const Color amberGoldBg = Color(0x1AFBBF24);

  /// amberGold 30% — 인사이트/팁 테두리
  static const Color amberGoldBorder = Color(0x4DFBBF24);

  /// skyBlue base (0xFF60A5FA)
  static const Color attentionBlue = Color(0xFF60A5FA);

  /// skyBlue 10% — 주의 인사이트 배경
  static const Color attentionBlueBg = Color(0x1A60A5FA);

  /// skyBlue 30% — 주의 인사이트 테두리
  static const Color attentionBlueBorder = Color(0x4D60A5FA);

  /// teal (0xFF00897B)
  static const Color teal = Color(0xFF00897B);

  /// teal 15% — SGA 뱃지 배경
  static const Color tealLight = Color(0x2600897B);

  // --- Misc ---

  /// Colors.grey 30% — 디바이더
  static const Color greyBorder = Color(0x4D9E9E9E);

  /// Colors.amber 20% — 오너 표시 배경
  static const Color amberSelected = Color(0x33FFC107);
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

  // ========================================
  // Sprint 19.5: Primary Alpha Variants
  // ========================================

  /// primary 30% — 힌트 텍스트
  static const Color primaryHint = Color(0x4DE9ECEF); // 2건 사용

  /// primary 50% — 중간 텍스트
  static const Color primaryMedium = Color(0x80E9ECEF);

  /// primary 60% — 소프트 텍스트
  static const Color primarySoft = Color(0x99E9ECEF);

  /// primary 70% — 부제목 텍스트
  static const Color primaryStrong = Color(0xB3E9ECEF);

  /// primary 80% — 강조 텍스트
  static const Color primaryBold = Color(0xCCE9ECEF);

  // ========================================
  // Sprint 19.5: Tertiary Alpha Variants
  // ========================================

  /// tertiary 50% — 서브 텍스트
  static const Color tertiaryMedium = Color(0x806C757D); // 2건 사용
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

  // ========================================
  // Sprint 19.5: Sleep Alpha Variants
  // ========================================

  /// sleep 8% — 울트라 서브틀
  static const Color sleepSubtle = Color(0x149575CD); // 2건 사용

  /// sleep 15% — 라이트 배경
  static const Color sleepLight = Color(0x269575CD); // 2건 사용

  /// sleep 20% — 선택 상태
  static const Color sleepSelected = Color(0x339575CD);

  /// sleep 50% — 중간 강조
  static const Color sleepMedium = Color(0x809575CD); // 2건 사용

  // ========================================
  // Sprint 19.5: Feeding Alpha Variants
  // ========================================

  /// feeding 20% — 선택 상태
  static const Color feedingSelected = Color(0x33FFB74D); // 2건 사용

  /// feeding 50% — 중간 강조
  static const Color feedingMedium = Color(0x80FFB74D);

  // ========================================
  // Sprint 21 Phase 4: 추가 Activity Alpha 토큰
  // ========================================

  /// sleep 30% — 수면 보더
  static const Color sleepBorder = Color(0x4D9575CD);

  /// sleep 40% — 수면 카드 보더
  static const Color sleepCardBorder = Color(0x669575CD);

  /// sleep 60% — 수면 아이콘 비활성
  static const Color sleepStrong = Color(0x999575CD);

  /// play 30% — 놀이 보더
  static const Color playBorder = Color(0x4D81C784);

  // ========================================
  // Sprint 21 Phase 4: Statistics Alpha 토큰
  // ========================================

  /// sleep 70% — 차트 슬라이스 (낮잠)
  static const Color sleepSlice = Color(0xB39575CD);

  /// feeding 70% — 차트 슬라이스 (분유)
  static const Color feedingSlice = Color(0xB3FFB74D);

  /// feeding 50% — 차트 슬라이스 (이유식)
  static const Color feedingSolidSlice = Color(0x80FFB74D);

  /// diaper 70% — 차트 슬라이스 (대변)
  static const Color diaperSlice = Color(0xB34FC3F7);

  /// diaper 50% — 차트 슬라이스 (혼합)
  static const Color diaperMixSlice = Color(0x804FC3F7);

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

  // ========================================
  // Sprint 19.5: Error Alpha Variants
  // ========================================

  /// error 10% — 에러 배경
  static const Color errorBg = Color(0x1AE87878);

  /// error 15% — 에러 라이트 배경
  static const Color errorLight = Color(0x26E87878); // 2건 사용

  /// error 30% — 에러 테두리
  static const Color errorBorder = Color(0x4DE87878); // 2건 사용

  /// error 70% — 에러 강조 텍스트
  static const Color errorStrong = Color(0xB3E87878); // 2건 사용

  // ========================================
  // Sprint 19.5: Warning Alpha Variants
  // ========================================

  /// warning 30% — 경고 테두리
  static const Color warningBorder = Color(0x4DE8B87E);

  // ========================================
  // Sprint 21 Phase 4: 추가 Status Alpha 토큰
  // ========================================

  /// warning 10% — 경고 배경
  static const Color warningBg = Color(0x1AE8B87E);

  /// warning 15% — 경고 라이트
  static const Color warningLight = Color(0x26E8B87E);

  /// success 10% — 성공 배경
  static const Color successBg = Color(0x1A5FB37B);

  /// error 20% — 에러 선택/원형
  static const Color errorSelected = Color(0x33E87878);

  /// error 80% — 에러 매우 강조
  static const Color errorBold = Color(0xCCE87878);

  /// info 10% — 정보 배경
  static const Color infoBg = Color(0x1A7BB8E8);

  /// info 30% — 정보 테두리
  static const Color infoBorder = Color(0x4D7BB8E8);
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

/// Cry Analysis Colors (울음 분석 컬러)
///
/// Phase 2: AI 울음 분석 기능용 색상 시스템
class LuluCryAnalysisColors {
  /// Primary - Deep Purple (울음 분석 메인 색상)
  static const Color primary = Color(0xFF7E57C2);

  /// 배경색 (10% opacity)
  static Color get primaryBg => primary.withValues(alpha: 0.1);

  /// 녹음 중 - Coral Orange
  static const Color recording = Color(0xFFFF7043);

  /// 녹음 중 배경
  static Color get recordingBg => recording.withValues(alpha: 0.15);

  /// 분석 중 - Amber
  static const Color analyzing = Color(0xFFFFB300);

  /// 분석 완료 - Success Green
  static const Color complete = LuluStatusColors.success;

  /// 카드 배경 (surfaceCard와 동일)
  static const Color cardBackground = LuluColors.surfaceCard;

  /// CTA 버튼 배경 (Midnight Blue 계열)
  static const Color ctaButton = LuluColors.deepBlue;

  /// CTA 버튼 텍스트
  static const Color ctaButtonText = LuluTextColors.primary;
}

/// Badge Colors (뱃지 컬러)
///
/// NEW, Premium 등 뱃지용 색상
class LuluBadgeColors {
  /// NEW 뱃지 - Orange
  static const Color newBadge = Color(0xFFFF9800);

  /// NEW 뱃지 텍스트
  static const Color newBadgeText = Color(0xFFFFFFFF);

  /// Premium 뱃지 - Gold
  static const Color premiumBadge = Color(0xFFFFD700);

  /// Premium 뱃지 텍스트
  static const Color premiumBadgeText = Color(0xFF1B263B);

  /// Beta 뱃지 - Teal
  static const Color betaBadge = Color(0xFF26A69A);

  /// Beta 뱃지 텍스트
  static const Color betaBadgeText = Color(0xFFFFFFFF);
}

/// Pattern Colors (패턴 차트 컬러)
///
/// 작업 지시서 v2.0: 주간 패턴 차트 및 타임바 색상
/// Sprint 19: 밤잠/낮잠 솔리드 컬러 분리
class LuluPatternColors {
  /// 밤잠 (21:00 ~ 06:00) - 어두운 보라
  static const Color nightSleep = Color(0xFF5B5381);

  /// 낮잠 (06:00 ~ 21:00) - 밝은 보라 (솔리드)
  static const Color daySleep = Color(0xFF9D8CD6);

  /// 수유
  static const Color feeding = Color(0xFF4A90D9); // skyBlue

  /// 기저귀
  static const Color diaper = Color(0xFF6FCF97); // mintGreen

  /// 빈 시간 (깨어있음)
  static const Color empty = Colors.transparent;

  /// 빈 시간 테두리
  static Color get emptyBorder => LuluTextColors.tertiary.withValues(alpha: 0.3);

  /// 수정 버튼
  static const Color editAction = Color(0xFF4A90D9); // skyBlue

  /// 삭제 버튼
  static const Color deleteAction = Color(0xFFE57373); // soft red

  /// 현재 시간 마커
  static const Color currentTimeMarker = Color(0xFFFF7043); // coral
}

/// Statistics Colors (통계 화면 컬러)
///
/// 작업 지시서 v1.2.1: 통계 화면 전용 색상 시스템
class LuluStatisticsColors {
  /// 수면 - Soft Purple
  static const Color sleep = LuluActivityColors.sleep;

  /// 수유 - Soft Orange
  static const Color feeding = LuluActivityColors.feeding;

  /// 기저귀 - Soft Blue
  static const Color diaper = LuluActivityColors.diaper;

  /// 울음 - Coral
  static const Color crying = Color(0xFFFF7043);

  /// 증가 (긍정) - Green
  static const Color increase = Color(0xFF5FB37B);

  /// 감소 (부정 or 주의) - Red
  static const Color decrease = Color(0xFFE87878);

  /// 보합 - Gray
  static const Color neutral = Color(0xFF6C757D);

  /// 낮잠 비율 - Light Purple
  static const Color napRatio = Color(0xFFB39DDB);

  /// 밤잠 비율 - Dark Purple
  static const Color nightRatio = Color(0xFF7E57C2);

  /// 모유 비율 - Soft Orange
  static const Color breastMilkRatio = Color(0xFFFFCC80);

  /// 분유 비율 - Amber
  static const Color formulaRatio = Color(0xFFFFD54F);

  /// 이유식 비율 - Yellow Green
  static const Color solidFoodRatio = Color(0xFFDCE775);

  /// 소변 비율 - Light Blue
  static const Color wetRatio = Color(0xFF81D4FA);

  /// 대변 비율 - Brown
  static const Color dirtyRatio = Color(0xFFBCAAA4);

  /// 혼합 비율 - Teal
  static const Color bothRatio = Color(0xFF80CBC4);

  // ========================================
  // Sprint 21 Phase 4: Crying Alpha 토큰
  // ========================================

  /// crying 80% — 차트 슬라이스 (피곤)
  static const Color cryingTired = Color(0xCCFF7043);

  /// crying 60% — 차트 슬라이스 (가스)
  static const Color cryingGas = Color(0x99FF7043);

  /// crying 40% — 차트 슬라이스 (불편)
  static const Color cryingDiscomfort = Color(0x66FF7043);
}
