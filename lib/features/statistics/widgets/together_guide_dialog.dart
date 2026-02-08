import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart';

/// 함께 보기 안내 다이얼로그
///
/// 작업 지시서 v1.2.1: 함께 보기 최초 진입 시 안내
/// "각 아기는 고유한 패턴을 가지고 있어요 💜"
class TogetherGuideDialog extends StatelessWidget {
  const TogetherGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return AlertDialog(
      backgroundColor: LuluColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LuluRadius.md),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 하트 아이콘
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: LuluColors.lavenderMist.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.favorite_rounded,
                size: 32,
                color: LuluColors.lavenderMist,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 메시지
          Text(
            l10n?.statisticsTogetherViewGuide ?? 'Each baby has their own unique pattern',
            style: LuluTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            '서로 다른 패턴도 모두 정상이에요',
            style: LuluTextStyles.bodySmall.copyWith(
              color: LuluTextColors.secondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: LuluColors.lavenderMist,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('알겠어요'),
          ),
        ),
      ],
    );
  }
}
