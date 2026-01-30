import 'package:flutter/material.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';

/// 성장 화면 Error 상태 (로딩 실패)
///
/// 에러 메시지와 재시도 버튼 제공
class GrowthErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool canRetry;

  const GrowthErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.canRetry = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LuluSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이콘
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: LuluStatusColors.error.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('😥', style: TextStyle(fontSize: 40)),
              ),
            ),

            const SizedBox(height: LuluSpacing.xl),

            // 메시지
            Text(
              '데이터를 불러오지 못했어요',
              style: LuluTextStyles.titleMedium.copyWith(
                color: LuluTextColors.primary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: LuluSpacing.md),

            Text(
              message,
              style: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: LuluSpacing.xxl),

            // 재시도 버튼
            if (canRetry)
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LuluColors.surfaceElevated,
                    foregroundColor: LuluTextColors.primary,
                    padding: const EdgeInsets.symmetric(
                      vertical: LuluSpacing.md,
                      horizontal: LuluSpacing.lg,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔄', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: LuluSpacing.sm),
                      Text(
                        '다시 시도',
                        style: LuluTextStyles.bodyMedium.copyWith(
                          color: LuluTextColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
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
}
