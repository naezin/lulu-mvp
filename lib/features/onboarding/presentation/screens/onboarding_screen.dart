import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/family_model.dart';
import '../../../../data/models/baby_model.dart';
import '../providers/onboarding_provider.dart';
import 'welcome_screen.dart';
import 'baby_count_screen.dart';
import 'baby_info_screen.dart';
import 'preterm_info_screen.dart';
import 'multiple_birth_tip_screen.dart';
import 'completion_screen.dart';
import '../../../../core/design_system/lulu_radius.dart';
import '../../../../core/design_system/lulu_icons.dart';

/// 온보딩 완료 콜백 타입
typedef OnboardingCompleteCallback = void Function(
  FamilyModel family,
  List<BabyModel> babies,
);

/// 온보딩 메인 화면
/// 모든 온보딩 단계를 관리하고 네비게이션 처리
class OnboardingScreen extends StatelessWidget {
  /// 온보딩 완료 콜백 (family와 babies 데이터 포함)
  final OnboardingCompleteCallback? onCompleteWithData;

  /// 단순 완료 콜백 (하위 호환용)
  final VoidCallback? onComplete;

  const OnboardingScreen({
    super.key,
    this.onCompleteWithData,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingProvider(),
      child: _OnboardingContent(
        onComplete: onComplete,
        onCompleteWithData: onCompleteWithData,
      ),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  final VoidCallback? onComplete;
  final OnboardingCompleteCallback? onCompleteWithData;

  const _OnboardingContent({
    this.onComplete,
    this.onCompleteWithData,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 바 (진행률 + 뒤로가기)
            _OnboardingHeader(
              showBackButton: provider.currentStep != OnboardingStep.welcome,
              progress: provider.progress,
              onBack: () => provider.previousStep(),
            ),

            // 컨텐츠 영역
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildCurrentStep(provider.currentStep),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.welcome => const WelcomeScreen(key: ValueKey('welcome')),
      OnboardingStep.babyCount => const BabyCountScreen(key: ValueKey('babyCount')),
      OnboardingStep.babyInfo => const BabyInfoScreen(key: ValueKey('babyInfo')),
      OnboardingStep.pretermInfo => const PretermInfoScreen(key: ValueKey('pretermInfo')),
      OnboardingStep.multipleBirthTip => const MultipleBirthTipScreen(key: ValueKey('multipleBirthTip')),
      OnboardingStep.completion => CompletionScreen(
          key: const ValueKey('completion'),
          onComplete: onComplete,
          onCompleteWithData: onCompleteWithData,
        ),
    };
  }
}

class _OnboardingHeader extends StatelessWidget {
  final bool showBackButton;
  final double progress;
  final VoidCallback onBack;

  const _OnboardingHeader({
    required this.showBackButton,
    required this.progress,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // 뒤로가기 버튼 행
          Row(
            children: [
              if (showBackButton)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(
                    LuluIcons.backIos,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                )
              else
                const SizedBox(width: 48),
              const Spacer(),
              // 스킵 버튼 (필요시 활성화)
              // TextButton(
              //   onPressed: () {},
              //   child: const Text('건너뛰기'),
              // ),
              const SizedBox(width: 48),
            ],
          ),

          const SizedBox(height: 8),

          // 진행률 바
          ClipRRect(
            borderRadius: BorderRadius.circular(LuluRadius.indicator),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.surfaceElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.lavenderMist,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
