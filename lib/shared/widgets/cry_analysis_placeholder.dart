import 'package:flutter/material.dart';

import '../../core/design_system/lulu_colors.dart';
import '../../core/design_system/lulu_spacing.dart';
import '../../core/design_system/lulu_typography.dart';

/// Phase 2 울음 분석 예약 영역 (Sprint 6 Day 2)
///
/// MVP-F에서는 Placeholder로 표시
/// Phase 2에서 실제 울음 분석 기능으로 교체 예정
class CryAnalysisPlaceholder extends StatelessWidget {
  /// 터치 시 콜백 (Phase 2 예고 다이얼로그 등)
  final VoidCallback? onTap;

  const CryAnalysisPlaceholder({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showComingSoonDialog(context),
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(
          horizontal: LuluSpacing.lg,
          vertical: LuluSpacing.md,
        ),
        decoration: BoxDecoration(
          color: LuluColors.lavenderMist.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: LuluColors.lavenderMist.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: LuluColors.lavenderMist.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  '🔊',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: LuluSpacing.md),
            // 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '울음 분석 기능 준비 중',
                    style: LuluTextStyles.bodyMedium.copyWith(
                      color: LuluTextColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Phase 2에서 만나요!',
                    style: LuluTextStyles.caption.copyWith(
                      color: LuluTextColors.tertiary,
                    ),
                  ),
                ],
              ),
            ),
            // Coming Soon 배지
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: LuluSpacing.sm,
                vertical: LuluSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: LuluColors.lavenderMist.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Coming Soon',
                style: LuluTextStyles.caption.copyWith(
                  color: LuluColors.lavenderMist,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LuluColors.deepBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Text('🔊', style: TextStyle(fontSize: 28)),
            const SizedBox(width: LuluSpacing.sm),
            Text(
              '울음 분석',
              style: LuluTextStyles.titleMedium.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
          ],
        ),
        content: Text(
          'AI 기반 울음 분석 기능이\nPhase 2에서 출시됩니다.\n\n아기의 울음 패턴을 분석하여\n배고픔, 졸림, 불편함 등을\n구분해드릴게요.',
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '확인',
              style: LuluTextStyles.labelMedium.copyWith(
                color: LuluColors.lavenderMist,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
