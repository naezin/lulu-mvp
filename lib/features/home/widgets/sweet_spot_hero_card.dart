import 'package:flutter/material.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';

/// Sweet Spot 히어로 카드
///
/// 다음 수면 추천 시간을 시각적으로 표시
/// 조산아의 경우 교정연령 기준으로 계산
class SweetSpotHeroCard extends StatelessWidget {
  final String? babyName;
  final int? correctedAgeMonths;
  final bool isPreterm;
  final String recommendedTime;
  final int minutesUntil;
  final double progress; // 0.0 ~ 1.0

  const SweetSpotHeroCard({
    super.key,
    this.babyName,
    this.correctedAgeMonths,
    this.isPreterm = false,
    this.recommendedTime = '14:30',
    this.minutesUntil = 25,
    this.progress = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.lg),
      decoration: BoxDecoration(
        color: LuluColors.deepBlue,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: LuluColors.lavenderMist.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              const Text('🌙', style: TextStyle(fontSize: 24)),
              const SizedBox(width: LuluSpacing.sm),
              Text(
                babyName != null ? '$babyName의 Sweet Spot' : 'Sweet Spot',
                style: LuluTextStyles.titleMedium.copyWith(
                  color: LuluTextColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: LuluSpacing.lg),

          // 추천 시간
          Center(
            child: Column(
              children: [
                Text(
                  '다음 수면 추천',
                  style: LuluTextStyles.bodyMedium.copyWith(
                    color: LuluTextColors.secondary,
                  ),
                ),
                const SizedBox(height: LuluSpacing.xs),
                Text(
                  recommendedTime,
                  style: LuluTextStyles.counter.copyWith(
                    color: LuluColors.lavenderMist,
                  ),
                ),
                Text(
                  '($minutesUntil분 후)',
                  style: LuluTextStyles.bodyMedium.copyWith(
                    color: LuluTextColors.secondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: LuluSpacing.lg),

          // 프로그레스 바
          _buildProgressBar(),

          const SizedBox(height: LuluSpacing.sm),

          // 범례
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '↑ 지금',
                style: LuluTextStyles.caption.copyWith(
                  color: LuluTextColors.tertiary,
                ),
              ),
              Text(
                '↑ Sweet Spot',
                style: LuluTextStyles.caption.copyWith(
                  color: LuluColors.lavenderMist,
                ),
              ),
            ],
          ),

          const SizedBox(height: LuluSpacing.lg),

          // 교정연령 정보 (조산아용)
          if (isPreterm && correctedAgeMonths != null) _buildCorrectedAgeInfo(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: LuluColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // 진행 바
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      LuluColors.lavenderMist.withValues(alpha: 0.5),
                      LuluColors.lavenderMist,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Sweet Spot 마커
              Positioned(
                left: constraints.maxWidth * 0.8 - 2,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: LuluColors.champagneGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCorrectedAgeInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.md,
        vertical: LuluSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: LuluColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 14)),
              const SizedBox(width: LuluSpacing.xs),
              Text(
                '교정연령: $correctedAgeMonths개월',
                style: LuluTextStyles.bodySmall.copyWith(
                  color: LuluTextColors.secondary,
                ),
              ),
            ],
          ),
          Text(
            'Fenton 차트 적용',
            style: LuluTextStyles.caption.copyWith(
              color: LuluColors.lavenderMist,
            ),
          ),
        ],
      ),
    );
  }
}
