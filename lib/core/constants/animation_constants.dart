import 'package:flutter/material.dart';

/// LULU 애니메이션 상수
///
/// Phase 4 v1.1 스펙 기준:
/// - 카드 등장: 250ms, easeOut
/// - 진행률 바: 250ms, easeInOut
/// - 차트 그리기: 600ms, easeOutCubic
/// - 탭 전환: 250ms, easeInOut
class LuluAnimations {
  LuluAnimations._();

  // Duration
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration chart = Duration(milliseconds: 600);
  static const Duration pageTransition = Duration(milliseconds: 300);

  // Curves
  static const Curve standard = Curves.easeInOut;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
  static const Curve bounce = Curves.elasticOut;
  static const Curve chartCurve = Curves.easeOutCubic;
  static const Curve pageEnter = Curves.easeOutCubic;
  static const Curve pageExit = Curves.easeInCubic;
}

/// LULU 페이지 라우트 트랜지션
///
/// 슬라이드 + 페이드 조합으로 부드러운 화면 전환
class LuluPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final RouteSettings? routeSettings;

  LuluPageRoute({
    required this.page,
    this.routeSettings,
  }) : super(
          settings: routeSettings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: LuluAnimations.pageTransition,
          reverseTransitionDuration: LuluAnimations.pageTransition,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 슬라이드 (오른쪽에서 왼쪽으로)
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.2, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: LuluAnimations.pageEnter,
            ));

            // 페이드
            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: LuluAnimations.enter,
            ));

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}

/// 모달 스타일 페이지 라우트 (아래에서 위로)
class LuluModalRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final RouteSettings? routeSettings;

  LuluModalRoute({
    required this.page,
    this.routeSettings,
  }) : super(
          settings: routeSettings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: LuluAnimations.pageTransition,
          reverseTransitionDuration: LuluAnimations.pageTransition,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 슬라이드 (아래에서 위로)
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: LuluAnimations.pageEnter,
            ));

            // 페이드
            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: LuluAnimations.enter,
            ));

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}
