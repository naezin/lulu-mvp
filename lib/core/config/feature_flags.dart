/// Feature Flags for LULU App
///
/// 미완성 기능을 숨기거나 A/B 테스트에 사용
/// 출시 전 false로 설정하여 안전하게 배포
library;

class FeatureFlags {
  FeatureFlags._();

  // ============================================================
  // Phase 2: 울음 분석 기능
  // ============================================================

  /// 울음 분석 기능 활성화 여부
  /// - true: 홈 화면에 울음 분석 버튼 표시
  /// - false: 울음 분석 기능 숨김 (출시 시 기본값)
  static const bool enableCryAnalysis = false;

  /// 울음 분석 결과 상세 보기
  /// enableCryAnalysis가 true일 때만 의미 있음
  static const bool enableCryAnalysisHistory = false;

  // ============================================================
  // Phase 3: Apple Watch 연동
  // ============================================================

  /// Apple Watch 연동 기능
  static const bool enableWatchIntegration = false;

  // ============================================================
  // 개발/디버그 기능
  // ============================================================

  /// 개발자 모드 (상세 로그, 디버그 UI)
  static const bool enableDevMode = false;

  /// 온보딩 스킵 (개발 편의용)
  static const bool skipOnboarding = false;

  // ============================================================
  // 헬퍼 메서드
  // ============================================================

  /// 현재 활성화된 피처 목록 (디버그용)
  static List<String> get enabledFeatures {
    final features = <String>[];
    if (enableCryAnalysis) features.add('cry_analysis');
    if (enableCryAnalysisHistory) features.add('cry_analysis_history');
    if (enableWatchIntegration) features.add('watch_integration');
    if (enableDevMode) features.add('dev_mode');
    if (skipOnboarding) features.add('skip_onboarding');
    return features;
  }
}
