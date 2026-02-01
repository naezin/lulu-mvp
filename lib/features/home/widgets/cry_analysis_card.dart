import 'package:flutter/material.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_radius.dart';

/// 울음 분석 카드 (홈 화면용)
///
/// Phase 2: AI 울음 분석 기능 진입점
/// SweetSpotCard 아래에 배치
///
/// 시안: A-1-2 CTA 버튼 강조형
/// 검증: SUS 85.5점, TTC 1.9초
class CryAnalysisCard extends StatelessWidget {
  /// 카드 또는 CTA 버튼 탭 시 콜백
  final VoidCallback onTap;

  /// NEW 배지 표시 여부 (신규 사용자 7일간)
  final bool showNewBadge;

  const CryAnalysisCard({
    super.key,
    required this.onTap,
    this.showNewBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(LuluSpacing.lg),
        decoration: BoxDecoration(
          // SweetSpotCard와 동일한 스타일
          color: LuluColors.surfaceCard,
          borderRadius: BorderRadius.circular(LuluRadius.md),
          border: Border.all(
            color: LuluColors.glassBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 아이콘 + 제목 + NEW 배지
            Row(
              children: [
                Icon(
                  LuluIcons.microphone,
                  color: LuluCryAnalysisColors.primary,
                  size: LuluIcons.sizeMD,
                ),
                const SizedBox(width: LuluSpacing.sm),
                Text(
                  '울음 분석',
                  style: LuluTextStyles.titleSmall.copyWith(
                    color: LuluTextColors.primary,
                  ),
                ),
                const Spacer(),
                if (showNewBadge) _buildNewBadge(),
              ],
            ),

            const SizedBox(height: LuluSpacing.sm),

            // 중단: 설명 텍스트
            Text(
              '아기가 왜 우는지 알아보세요',
              style: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),

            const SizedBox(height: LuluSpacing.md),

            // 하단: CTA 버튼
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LuluSpacing.md,
                  vertical: LuluSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: LuluCryAnalysisColors.primary,
                  borderRadius: BorderRadius.circular(LuluRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '분석 시작하기',
                      style: LuluTextStyles.labelMedium.copyWith(
                        color: LuluTextColors.primary,
                      ),
                    ),
                    const SizedBox(width: LuluSpacing.xs),
                    Icon(
                      LuluIcons.forward,
                      size: LuluIcons.sizeXS,
                      color: LuluTextColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// NEW 배지 위젯
  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: LuluBadgeColors.newBadge,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'NEW',
        style: TextStyle(
          color: LuluBadgeColors.newBadgeText,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
