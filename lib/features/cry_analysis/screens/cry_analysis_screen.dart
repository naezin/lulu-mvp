import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
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
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        '울음 분석',
        style: LuluTextStyles.titleMedium.copyWith(
          color: LuluTextColors.primary,
        ),
      ),
      centerTitle: true,
      actions: [
        // 히스토리 버튼
        IconButton(
          icon: const Icon(Icons.history_rounded),
          onPressed: () {
            // TODO: 히스토리 화면 이동
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('히스토리 기능은 곧 추가됩니다.')),
            );
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
    return Column(
      children: [
        // 아이콘
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: LuluColors.lavenderMist.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.graphic_eq_rounded,
            size: 56,
            color: LuluColors.lavenderMist,
          ),
        ),
        const SizedBox(height: LuluSpacing.xl),
        Text(
          '아기가 울고 있나요?',
          style: LuluTextStyles.titleLarge.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        const SizedBox(height: LuluSpacing.sm),
        Text(
          '버튼을 누르고 울음 소리를 들려주세요',
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
              color: LuluColors.lavenderMist.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(LuluRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: LuluColors.lavenderMist,
                ),
                const SizedBox(width: LuluSpacing.xs),
                Text(
                  '교정연령 ${baby.correctedAgeInWeeks ?? 0}주 기준으로 분석해요',
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
                  color: LuluStatusColors.error.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: LuluStatusColors.error,
                    width: 3,
                  ),
                ),
                child: Icon(
                  Icons.mic_rounded,
                  size: 56,
                  color: LuluStatusColors.error,
                ),
              ),
            ),
            const SizedBox(height: LuluSpacing.xl),
            Text(
              '듣고 있어요...',
              style: LuluTextStyles.titleLarge.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
            const SizedBox(height: LuluSpacing.sm),
            Text(
              '2-10초 동안 울음 소리를 들려주세요',
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
          '분석 중...',
          style: LuluTextStyles.titleLarge.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        const SizedBox(height: LuluSpacing.sm),
        Text(
          'AI가 울음 패턴을 분석하고 있어요',
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
                '분석 상세',
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
              color: LuluColors.lavenderMist.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(LuluRadius.sm),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: LuluColors.lavenderMist,
                ),
                const SizedBox(width: LuluSpacing.sm),
                Expanded(
                  child: Text(
                    '교정연령 ${result.correctedAgeWeeks ?? 0}주 기준으로 '
                    '신뢰도를 보정했어요.',
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
        '피드백을 보내주셨어요. 감사합니다!',
        style: LuluTextStyles.caption.copyWith(
          color: LuluTextColors.tertiary,
        ),
      );
    }

    return Column(
      children: [
        Text(
          '분석 결과가 맞나요?',
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
        const SizedBox(height: LuluSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFeedbackButton(
              label: '맞아요',
              icon: Icons.thumb_up_outlined,
              color: LuluStatusColors.success,
              onTap: () {
                provider.addFeedback(latestRecord.id, CryFeedback.accurate);
              },
            ),
            const SizedBox(width: LuluSpacing.md),
            _buildFeedbackButton(
              label: '아니에요',
              icon: Icons.thumb_down_outlined,
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
        color: LuluStatusColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(LuluRadius.md),
        border: Border.all(
          color: LuluStatusColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: LuluStatusColors.error,
          ),
          const SizedBox(height: LuluSpacing.md),
          Text(
            provider.errorMessage ?? '알 수 없는 오류가 발생했어요.',
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuluSpacing.md),
          TextButton(
            onPressed: () => provider.clearError(),
            child: Text(
              '다시 시도',
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
            Icons.analytics_outlined,
            size: 16,
            color: remaining > 0 ? LuluTextColors.secondary : LuluStatusColors.warning,
          ),
          const SizedBox(width: LuluSpacing.xs),
          Text(
            '오늘 남은 분석: $remaining회',
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
                '업그레이드',
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
        color: LuluColors.deepBlue.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: LuluTextColors.tertiary,
          ),
          const SizedBox(width: LuluSpacing.sm),
          Expanded(
            child: Text(
              '이 분석 결과는 참고용이며, 의료적 조언을 대체하지 않습니다. '
              '${baby.isPreterm ? "조산아의 울음 패턴은 개인차가 크므로, " : ""}'
              '걱정되시면 담당 의료진과 상담하세요.',
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
            Icons.child_care_rounded,
            size: 64,
            color: LuluTextColors.tertiary,
          ),
          const SizedBox(height: LuluSpacing.md),
          Text(
            '아기 정보를 먼저 등록해주세요',
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
}
