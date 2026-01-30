import 'package:flutter/material.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';

/// 성장 화면 Empty 상태 (측정 기록 없음)
///
/// 긍정적 메시지와 함께 첫 기록 유도
class GrowthEmptyState extends StatelessWidget {
  final String? babyName;
  final VoidCallback onAddRecord;

  const GrowthEmptyState({
    super.key,
    this.babyName,
    required this.onAddRecord,
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
                color: LuluColors.lavenderMist.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('📏', style: TextStyle(fontSize: 40)),
              ),
            ),

            const SizedBox(height: LuluSpacing.xl),

            // 메시지
            Text(
              babyName != null
                  ? '$babyName의 첫 성장 기록을\n남겨보세요!'
                  : '첫 성장 기록을\n남겨보세요!',
              style: LuluTextStyles.titleMedium.copyWith(
                color: LuluTextColors.primary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: LuluSpacing.md),

            Text(
              '소아과 정기검진 후 기록하면\n성장 추이를 확인할 수 있어요',
              style: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: LuluSpacing.xxl),

            // CTA 버튼
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: onAddRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LuluColors.lavenderMist,
                  foregroundColor: LuluColors.midnightNavy,
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
                    const Text('📝', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: LuluSpacing.sm),
                    Text(
                      '첫 기록 남기기',
                      style: LuluTextStyles.bodyMedium.copyWith(
                        color: LuluColors.midnightNavy,
                        fontWeight: FontWeight.bold,
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
