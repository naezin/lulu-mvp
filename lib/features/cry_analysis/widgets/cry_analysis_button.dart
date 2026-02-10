import 'package:flutter/material.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_shadows.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../providers/cry_analysis_provider.dart';

/// 울음 분석 버튼
///
/// Phase 2: AI 울음 분석 기능
/// 상태에 따라 다른 UI 표시 (녹음/중지/분석중)
class CryAnalysisButton extends StatelessWidget {
  final CryAnalysisState state;
  final AnimationController pulseAnimation;
  final VoidCallback onPressed;
  final VoidCallback onCancel;

  const CryAnalysisButton({
    super.key,
    required this.state,
    required this.pulseAnimation,
    required this.onPressed,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;

    return Column(
      children: [
        // 메인 버튼
        _buildMainButton(l10n),

        // 취소 버튼 (녹음 중에만)
        if (state == CryAnalysisState.recording) ...[
          const SizedBox(height: LuluSpacing.md),
          _buildCancelButton(l10n),
        ],
      ],
    );
  }

  Widget _buildMainButton(S l10n) {
    final isAnalyzing = state == CryAnalysisState.analyzing;
    final isRecording = state == CryAnalysisState.recording;

    return GestureDetector(
      onTap: isAnalyzing ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: isRecording ? 100 : 200,
        height: 56,
        decoration: BoxDecoration(
          gradient: isAnalyzing
              ? null
              : LinearGradient(
                  colors: isRecording
                      ? [LuluStatusColors.error, LuluStatusColors.errorBold]
                      : [LuluColors.lavenderMist, LuluColors.lavenderGlow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isAnalyzing ? LuluColors.softBlue : null,
          borderRadius: BorderRadius.circular(isRecording ? LuluRadius.xxl : LuluRadius.md),
          boxShadow: isAnalyzing
              ? null
              : LuluShadows.glow(
                  color: isRecording
                      ? LuluStatusColors.error
                      : LuluColors.lavenderMist,
                ),
        ),
        child: Center(
          child: _buildButtonContent(l10n),
        ),
      ),
    );
  }

  Widget _buildButtonContent(S l10n) {
    switch (state) {
      case CryAnalysisState.idle:
      case CryAnalysisState.completed:
      case CryAnalysisState.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LuluIcons.microphone,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: LuluSpacing.sm),
            Text(
              state == CryAnalysisState.idle ? l10n.cryAnalysisStart : l10n.cryReanalyzeShort,
              style: LuluTextStyles.labelLarge.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        );

      case CryAnalysisState.recording:
        return AnimatedBuilder(
          animation: pulseAnimation,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 1.0 + (pulseAnimation.value * 0.2),
                  child: const Icon(
                    LuluIcons.stop,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            );
          },
        );

      case CryAnalysisState.analyzing:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  LuluTextColors.secondary,
                ),
              ),
            ),
            const SizedBox(width: LuluSpacing.sm),
            Text(
              l10n.cryAnalyzingText,
              style: LuluTextStyles.labelMedium.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildCancelButton(S l10n) {
    return GestureDetector(
      onTap: onCancel,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LuluSpacing.lg,
          vertical: LuluSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: LuluColors.deepBlue,
          borderRadius: BorderRadius.circular(LuluRadius.lg),
        ),
        child: Text(
          l10n.cancel,
          style: LuluTextStyles.labelSmall.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
      ),
    );
  }
}
