import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';

/// Step 1: 환영 화면
/// "Lulu에 오신 것을 환영해요!"
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // 로고 영역 - 배경 없이 로고만
          Image.asset(
            'assets/icon/lulu_logo.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // 이미지 로드 실패 시 fallback 아이콘
              return const Icon(
                Icons.nightlight_round,
                size: 60,
                color: AppTheme.lavenderMist,
              );
            },
          ),

          const SizedBox(height: 48),

          // 환영 메시지
          Text(
            'Lulu에 오신 것을\n환영해요!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
          ),

          const SizedBox(height: 24),

          // 설명 텍스트
          Text(
            '아기의 수면, 수유, 기저귀를\n쉽고 빠르게 기록해 보세요',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
          ),

          const Spacer(flex: 3),

          // 시작하기 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<OnboardingProvider>().nextStep();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: AppTheme.lavenderMist,
                foregroundColor: AppTheme.midnightNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                '시작하기',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
