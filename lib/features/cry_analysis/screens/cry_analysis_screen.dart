import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/baby_model.dart';
import '../../home/providers/home_provider.dart';
import '../../../shared/widgets/baby_tab_bar.dart';
import '../models/models.dart';
import '../providers/cry_analysis_provider.dart';
import '../widgets/cry_analysis_button.dart';
import '../widgets/cry_result_card.dart';
import '../widgets/probability_bar.dart';

/// 울음 분석 화면
///
/// Phase 2: AI 울음 분석 기능
/// 메인 분석 화면 (녹음 → 분석 → 결과)
class CryAnalysisScreen extends StatefulWidget {
  const CryAnalysisScreen({super.key});

  @override
  State<CryAnalysisScreen> createState() => _CryAnalysisScreenState();
}

class _CryAnalysisScreenState extends State<CryAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  String? _selectedBabyId;

  @override
  void initState() {
    super.initState();

    // 펄스 애니메이션 (녹음 중 표시용)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Provider 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CryAnalysisProvider>();
      provider.initialize();

      // 첫 번째 아기 선택
      final homeProvider = context.read<HomeProvider>();
      final babies = homeProvider.babies;
      if (babies.isNotEmpty && _selectedBabyId == null) {
        setState(() {
          _selectedBabyId = babies.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuluColors.midnightNavy,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Consumer2<CryAnalysisProvider, HomeProvider>(
          builder: (context, cryProvider, homeProvider, _) {
            final family = homeProvider.family;
            final babies = homeProvider.babies;

            // 선택된 아기 확인
            BabyModel? selectedBaby;
            if (_selectedBabyId != null && babies.isNotEmpty) {
              selectedBaby = babies.firstWhere(
                (b) => b.id == _selectedBabyId,
                orElse: () => babies.first,
              );
            } else if (babies.isNotEmpty) {
              selectedBaby = babies.first;
              _selectedBabyId = selectedBaby.id;
            }

            return Column(
              children: [
                // 아기 탭바 (다태아)
                if (babies.length > 1)
                  BabyTabBar(
                    babies: babies,
                    selectedBabyId: _selectedBabyId,
                    onBabyChanged: (id) {
                      setState(() {
                        _selectedBabyId = id;
                      });
                      cryProvider.resetResult();
                    },
                  ),

                // 메인 콘텐츠
                Expanded(
                  child: _buildContent(cryProvider, selectedBaby, family?.id),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: LuluColors.midnightNavy,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LuluIcons.backIos),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        S.of(context)!.cryAnalysisTitle,
        style: LuluTextStyles.titleMedium.copyWith(
          color: LuluTextColors.primary,
        ),
      ),
      centerTitle: true,
      actions: [
        // 히스토리 버튼
        IconButton(
          icon: const Icon(LuluIcons.history),
          onPressed: () {
            // TODO: 히스토리 화면 이동
            AppToast.showText(S.of(context)!.cryHistoryComingSoon);
          },
        ),
      ],
    );
  }

  Widget _buildContent(
    CryAnalysisProvider provider,
    BabyModel? baby,
    String? familyId,
  ) {
    if (baby == null || familyId == null) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: LuluSpacing.screenPadding,
      child: Column(
        children: [
          const SizedBox(height: LuluSpacing.xl),

          // 상태별 UI
          _buildStateContent(provider, baby, familyId),

          const SizedBox(height: LuluSpacing.xxl),

          // 분석 버튼
          CryAnalysisButton(
            state: provider.state,
            pulseAnimation: _pulseController,
            onPressed: () => _handleAnalysisButton(provider, baby, familyId),
            onCancel: () => provider.cancelRecording(),
          ),

          const SizedBox(height: LuluSpacing.lg),

          // 남은 횟수 표시 (Free 사용자)
          if (!provider.isPremium) _buildRemainingCount(provider),

          const SizedBox(height: LuluSpacing.xxl),

          // 결과 표시
          if (provider.state == CryAnalysisState.completed &&
              provider.lastResult != null)
            _buildResult(provider, baby),

          // 에러 표시
          if (provider.state == CryAnalysisState.error &&
              provider.errorMessage != null)
            _buildError(provider),

          const SizedBox(height: LuluSpacing.huge),

          // 면책 조항
          _buildDisclaimer(baby),
        ],
      ),
    );
  }

  Widget _buildStateContent(
    CryAnalysisProvider provider,
    BabyModel baby,
    String familyId,
  ) {
    switch (provider.state) {
      case CryAnalysisState.idle:
        return _buildIdleState(baby);
      case CryAnalysisState.recording:
        return _buildRecordingState();
      case CryAnalysisState.analyzing:
        return _buildAnalyzingState();
      case CryAnalysisState.completed:
      case CryAnalysisState.error:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIdleState(BabyModel baby) {
    final l10n = S.of(context)!;
    return Column(
      children: [
        // 아이콘
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: LuluColors.lavenderBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            LuluIcons.soundWave,
            size: 56,
            color: LuluColors.lavenderMist,
          ),
        ),
        const SizedBox(height: LuluSpacing.xl),
        Text(
          l10n.cryIdleTitle,
          style: LuluTextStyles.titleLarge.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        const SizedBox(height: LuluSpacing.sm),
        Text(
          l10n.cryIdleHint,
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
          textAlign: TextAlign.center,
        ),
        if (baby.isPreterm) ...[
          const SizedBox(height: LuluSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LuluSpacing.md,
              vertical: LuluSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: LuluColors.lavenderBg,
              borderRadius: BorderRadius.circular(LuluRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LuluIcons.infoOutline,
                  size: 16,
                  color: LuluColors.lavenderMist,
                ),
                const SizedBox(width: LuluSpacing.xs),
                Text(
                  l10n.cryCorrectedAgeInfo(baby.correctedAgeInWeeks ?? 0),
                  style: LuluTextStyles.caption.copyWith(
                    color: LuluColors.lavenderMist,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecordingState() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.1);
        return Column(
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: LuluStatusColors.errorSelected,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: LuluStatusColors.error,
                    width: 3,
                  ),
                ),
                child: Icon(
                  LuluIcons.microphone,
                  size: 56,
                  color: LuluStatusColors.error,
                ),
              ),
            ),
            const SizedBox(height: LuluSpacing.xl),
            Text(
              S.of(context)!.cryListeningTitle,
              style: LuluTextStyles.titleLarge.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
            const SizedBox(height: LuluSpacing.sm),
            Text(
              S.of(context)!.cryListeningHint,
              style: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnalyzingState() {
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(
              LuluColors.lavenderMist,
            ),
          ),
        ),
        const SizedBox(height: LuluSpacing.xl),
        Text(
          S.of(context)!.cryAnalyzingText,
          style: LuluTextStyles.titleLarge.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        const SizedBox(height: LuluSpacing.sm),
        Text(
          S.of(context)!.cryAnalyzingHint,
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildResult(CryAnalysisProvider provider, BabyModel baby) {
    final result = provider.lastResult!;

    return Column(
      children: [
        // 메인 결과 카드
        CryResultCard(
          result: result,
          babyName: baby.name,
          onActionTap: () {
            // TODO: 관련 활동 기록 화면으로 이동
          },
        ),

        const SizedBox(height: LuluSpacing.lg),

        // 확률 분포
        Container(
          padding: LuluSpacing.cardPadding,
          decoration: BoxDecoration(
            color: LuluColors.deepBlue,
            borderRadius: BorderRadius.circular(LuluRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context)!.cryDetailTitle,
                style: LuluTextStyles.titleSmall.copyWith(
                  color: LuluTextColors.primary,
                ),
              ),
              const SizedBox(height: LuluSpacing.md),
              // 상위 3개 결과만 표시
              ...result.getTopResults(3).map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: LuluSpacing.sm),
                  child: ProbabilityBar(
                    cryType: entry.key,
                    probability: entry.value,
                    isHighlighted: entry.key == result.cryType,
                  ),
                );
              }),
            ],
          ),
        ),

        // 조산아 보정 안내
        if (result.isPretermAdjusted) ...[
          const SizedBox(height: LuluSpacing.md),
          Container(
            padding: const EdgeInsets.all(LuluSpacing.md),
            decoration: BoxDecoration(
              color: LuluColors.lavenderBg,
              borderRadius: BorderRadius.circular(LuluRadius.sm),
            ),
            child: Row(
              children: [
                Icon(
                  LuluIcons.infoOutline,
                  size: 20,
                  color: LuluColors.lavenderMist,
                ),
                const SizedBox(width: LuluSpacing.sm),
                Expanded(
                  child: Text(
                    S.of(context)!.cryPretermAdjustInfo(result.correctedAgeWeeks ?? 0),
                    style: LuluTextStyles.caption.copyWith(
                      color: LuluTextColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: LuluSpacing.lg),

        // 피드백 버튼
        _buildFeedbackButtons(provider),
      ],
    );
  }

  Widget _buildFeedbackButtons(CryAnalysisProvider provider) {
    final records = provider.records;
    if (records.isEmpty) return const SizedBox.shrink();

    final latestRecord = records.first;
    if (latestRecord.hasFeedback) {
      return Text(
        S.of(context)!.cryFeedbackThanks,
        style: LuluTextStyles.caption.copyWith(
          color: LuluTextColors.tertiary,
        ),
      );
    }

    return Column(
      children: [
        Text(
          S.of(context)!.cryFeedbackQuestion,
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
        const SizedBox(height: LuluSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFeedbackButton(
              label: S.of(context)!.cryFeedbackCorrect,
              icon: LuluIcons.thumbUp,
              color: LuluStatusColors.success,
              onTap: () {
                provider.addFeedback(latestRecord.id, CryFeedback.accurate);
              },
            ),
            const SizedBox(width: LuluSpacing.md),
            _buildFeedbackButton(
              label: S.of(context)!.cryFeedbackIncorrect,
              icon: LuluIcons.thumbDown,
              color: LuluStatusColors.error,
              onTap: () {
                provider.addFeedback(latestRecord.id, CryFeedback.inaccurate);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedbackButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LuluSpacing.lg,
          vertical: LuluSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(LuluRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: LuluSpacing.xs),
            Text(
              label,
              style: LuluTextStyles.labelSmall.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(CryAnalysisProvider provider) {
    return Container(
      padding: LuluSpacing.cardPadding,
      decoration: BoxDecoration(
        color: LuluStatusColors.errorBg,
        borderRadius: BorderRadius.circular(LuluRadius.md),
        border: Border.all(
          color: LuluStatusColors.errorBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            LuluIcons.errorOutline,
            size: 48,
            color: LuluStatusColors.error,
          ),
          const SizedBox(height: LuluSpacing.md),
          Text(
            _localizeCryError(provider.errorMessage, S.of(context)!),
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuluSpacing.md),
          TextButton(
            onPressed: () => provider.clearError(),
            child: Text(
              S.of(context)!.buttonRetry,
              style: LuluTextStyles.labelMedium.copyWith(
                color: LuluColors.lavenderMist,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingCount(CryAnalysisProvider provider) {
    final remaining = provider.remainingAnalyses;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.md,
        vertical: LuluSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: LuluColors.deepBlue,
        borderRadius: BorderRadius.circular(LuluRadius.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LuluIcons.analyticsOutlined,
            size: 16,
            color: remaining > 0 ? LuluTextColors.secondary : LuluStatusColors.warning,
          ),
          const SizedBox(width: LuluSpacing.xs),
          Text(
            S.of(context)!.cryRemainingCount(remaining),
            style: LuluTextStyles.caption.copyWith(
              color: remaining > 0 ? LuluTextColors.secondary : LuluStatusColors.warning,
            ),
          ),
          if (remaining == 0) ...[
            const SizedBox(width: LuluSpacing.sm),
            GestureDetector(
              onTap: () {
                // TODO: 프리미엄 업그레이드 화면
              },
              child: Text(
                S.of(context)!.buttonUpgrade,
                style: LuluTextStyles.caption.copyWith(
                  color: LuluColors.lavenderMist,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDisclaimer(BabyModel baby) {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.md),
      decoration: BoxDecoration(
        color: LuluColors.deepBlueMedium,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LuluIcons.infoOutline,
            size: 16,
            color: LuluTextColors.tertiary,
          ),
          const SizedBox(width: LuluSpacing.sm),
          Expanded(
            child: Text(
              baby.isPreterm
                  ? S.of(context)!.cryDisclaimerWithPreterm
                  : S.of(context)!.cryDisclaimer,
              style: LuluTextStyles.caption.copyWith(
                color: LuluTextColors.tertiary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LuluIcons.baby,
            size: 64,
            color: LuluTextColors.tertiary,
          ),
          const SizedBox(height: LuluSpacing.md),
          Text(
            S.of(context)!.cryEmptyBabyInfo,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAnalysisButton(
    CryAnalysisProvider provider,
    BabyModel baby,
    String familyId,
  ) {
    switch (provider.state) {
      case CryAnalysisState.idle:
      case CryAnalysisState.completed:
      case CryAnalysisState.error:
        // 녹음 시작
        provider.startAnalysis(baby: baby, familyId: familyId);
        break;
      case CryAnalysisState.recording:
        // 녹음 중지 및 분석
        provider.stopAndAnalyze(baby: baby, familyId: familyId);
        break;
      case CryAnalysisState.analyzing:
        // 분석 중에는 아무것도 안 함
        break;
    }
  }

  /// Map internal error codes to user-friendly localized messages
  String _localizeCryError(String? errorCode, S l10n) {
    return switch (errorCode) {
      'CRY_RECORDING_FAILED' => l10n.cryErrorUnknown,
      'CRY_ANALYSIS_FAILED' => l10n.cryErrorUnknown,
      'daily_limit_exceeded' => l10n.cryErrorUnknown,
      null => l10n.cryErrorUnknown,
      _ => l10n.cryErrorUnknown,
    };
  }
}
