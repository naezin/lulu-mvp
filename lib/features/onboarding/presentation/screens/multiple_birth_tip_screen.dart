import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/design_system/lulu_radius.dart';
import '../../../../core/design_system/lulu_icons.dart';

/// Step 5 (다태아 전용): 다둥이 기록 팁 안내
/// v5.0: "둘 다" 버튼 제거, 개별 기록 + 빠른 전환 강조
class MultipleBirthTipScreen extends StatelessWidget {
  const MultipleBirthTipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 48),

          // 제목
          Text(
            '다둥이 기록 팁',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 12),

          Text(
            '더 쉽게 기록할 수 있어요',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),

          const SizedBox(height: 48),

          // 팁 1: 탭으로 빠른 전환
          _TipCard(
            icon: LuluIcons.swapHoriz,
            title: '탭으로 빠른 전환',
            description: '상단 탭을 눌러 아기별 기록을\n빠르게 확인하고 전환해요 (1초 이내!)',
            color: AppTheme.lavenderMist,
          ),

          const SizedBox(height: 16),

          // 팁 2: 개별 통계
          _TipCard(
            icon: LuluIcons.barChart,
            title: '개별 통계',
            description: '각 아기의 수유, 수면, 기저귀 패턴을\n개별로 분석해드려요',
            color: AppTheme.babyAvatarColors[0],
          ),

          const SizedBox(height: 16),

          // 팁 3: 개별 알림
          _TipCard(
            icon: LuluIcons.notificationActive,
            title: '개별 알림',
            description: '각 아기 맞춤 수유/수면 시간을\n따로 알려드려요',
            color: AppTheme.babyAvatarColors[1],
          ),

          const SizedBox(height: 16),

          // 팁 4: 색상으로 구분
          _TipCard(
            icon: LuluIcons.indoorPlay,
            title: '색상으로 구분',
            description: '각 아기만의 색상으로\n한눈에 구분할 수 있어요',
            color: AppTheme.babyAvatarColors[2],
            showBabyColors: true,
            babyCount: provider.babyCount,
          ),

          const SizedBox(height: 32),

          // 다음 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => provider.nextStep(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: AppTheme.lavenderMist,
                foregroundColor: AppTheme.midnightNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LuluRadius.md),
                ),
              ),
              child: const Text(
                '알겠어요',
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

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool showBabyColors;
  final int babyCount;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.showBabyColors = false,
    this.babyCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(LuluRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14), // special: design system outer
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                ),
                if (showBabyColors) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(babyCount, (index) {
                      final colors = [
                        AppTheme.babyAvatarColors[0],
                        AppTheme.babyAvatarColors[1],
                        AppTheme.babyAvatarColors[2],
                        AppTheme.babyAvatarColors[3],
                      ];
                      return Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: colors[index],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: AppTheme.midnightNavy,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
