import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/onboarding_data_service.dart';
import '../../../../core/utils/sga_calculator.dart';
import '../providers/onboarding_provider.dart';
import 'onboarding_screen.dart' show OnboardingCompleteCallback;
import '../../../../core/design_system/lulu_radius.dart';
import '../../../../core/design_system/lulu_icons.dart';

/// Step 6: 온보딩 완료
/// 환영 메시지 + 홈으로 이동
class CompletionScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final OnboardingCompleteCallback? onCompleteWithData;

  const CompletionScreen({
    super.key,
    this.onComplete,
    this.onCompleteWithData,
  });

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // 체크 아이콘 (애니메이션)
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.successSoft,
                    AppTheme.successSoft.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: const Icon(
                LuluIcons.save,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 48),

          // 완료 메시지 (애니메이션)
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Text(
                  '준비 완료!',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  _getCompletionMessage(provider),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 아기 정보 요약
          FadeTransition(
            opacity: _fadeAnimation,
            child: _BabySummaryCard(
              babies: provider.babies,
            ),
          ),

          const Spacer(flex: 3),

          // 시작하기 버튼
          FadeTransition(
            opacity: _fadeAnimation,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : () => _handleComplete(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: AppTheme.lavenderMist,
                  foregroundColor: AppTheme.midnightNavy,
                  disabledBackgroundColor: AppTheme.surfaceElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(LuluRadius.md),
                  ),
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.midnightNavy,
                        ),
                      )
                    : const Text(
                        '시작하기',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  String _getCompletionMessage(OnboardingProvider provider) {
    // SGA-01: 출생 유형별 맞춤 메시지
    final babies = provider.babies;

    // SGA/조산아 여부 확인
    final hasSGA = babies.any((baby) {
      final classification = SGACalculator.getBirthClassification(
        gestationalWeeks: baby.isPreterm ? baby.gestationalWeeks : 40,
        birthWeightGrams: baby.birthWeightGrams,
      );
      return classification == BirthClassification.fullTermSGA;
    });

    final hasPreterm = babies.any((baby) => baby.isPreterm);

    if (provider.babyCount == 1) {
      final babyName = babies.first.name;

      if (hasPreterm) {
        return '$babyName의 교정연령에 맞춰\n발달을 꼼꼼히 기록해드릴게요';
      } else if (hasSGA) {
        return '$babyName의 성장을 세심하게\n추적해드릴게요';
      }
      return '$babyName의 육아 기록을\n시작할 준비가 되었어요';
    } else {
      final names = babies.map((b) => b.name).join(', ');

      if (hasPreterm) {
        return '$names의 교정연령에 맞춰\n발달을 꼼꼼히 기록해드릴게요';
      } else if (hasSGA) {
        return '$names의 성장을 세심하게\n추적해드릴게요';
      }
      return '$names의 육아 기록을\n시작할 준비가 되었어요';
    }
  }

  /// 온보딩 완료 처리
  /// 🆕 HOTFIX: 중복 체크 로직 제거 (main.dart에서 이미 처리)
  Future<void> _handleComplete(BuildContext context) async {
    final provider = context.read<OnboardingProvider>();

    try {
      // 온보딩 완료 → Supabase에 저장
      final result = await provider.completeOnboarding();

      // 디버그 로그
      debugPrint('[OK] [Onboarding] Family created: ${result.family.id}');
      for (final baby in result.babies) {
        debugPrint('[OK] [Onboarding] Baby created: ${baby.name}');
      }

      // SharedPreferences에 데이터 저장
      await OnboardingDataService.instance.saveOnboardingData(
        family: result.family,
        babies: result.babies,
      );

      // 콜백 호출 (데이터 포함)
      if (widget.onCompleteWithData != null) {
        widget.onCompleteWithData!(result.family, result.babies);
      } else {
        widget.onComplete?.call();
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: AppTheme.errorSoft,
        ),
      );
    }
  }
}

class _BabySummaryCard extends StatelessWidget {
  final List<BabyFormData> babies;

  const _BabySummaryCard({required this.babies});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(LuluRadius.lg),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < babies.length; i++) ...[
              if (i > 0) const Divider(height: 24),
              _BabyRow(
                index: i,
                baby: babies[i],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BabyRow extends StatelessWidget {
  final int index;
  final BabyFormData baby;

  const _BabyRow({
    required this.index,
    required this.baby,
  });

  /// SGA-01: 출생 유형 분류
  BirthClassification get _birthClassification {
    return SGACalculator.getBirthClassification(
      gestationalWeeks: baby.isPreterm ? baby.gestationalWeeks : 40,
      birthWeightGrams: baby.birthWeightGrams,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.babyAvatarColors[index % AppTheme.babyAvatarColors.length];
    final classification = _birthClassification;

    return Row(
      children: [
        // 아바타
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              baby.name.isNotEmpty ? baby.name[0] : '?',
              style: const TextStyle(
                color: AppTheme.midnightNavy,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 이름과 정보
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                baby.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                _getBabyInfo(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
              ),
            ],
          ),
        ),
        // SGA-01: 상태 배지 (조산아 또는 SGA)
        _buildStatusBadge(context, classification),
      ],
    );
  }

  /// SGA-01: 상태 배지 위젯
  Widget _buildStatusBadge(BuildContext context, BirthClassification classification) {
    switch (classification) {
      case BirthClassification.preterm:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.warningSoft.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(LuluRadius.xs),
          ),
          child: Text(
            '${baby.gestationalWeeks}주',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.warningSoft,
                  fontWeight: FontWeight.w600,
                ),
          ),
        );

      case BirthClassification.fullTermSGA:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF00897B).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(LuluRadius.xs),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LuluIcons.growth,
                size: 12,
                color: Color(0xFF00897B),
              ),
              const SizedBox(width: 4),
              Text(
                '성장 추적',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF00897B),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        );

      case BirthClassification.fullTermAGA:
        return const SizedBox.shrink();
    }
  }

  String _getBabyInfo() {
    if (baby.birthDate == null) return '';

    final now = DateTime.now();
    final diff = now.difference(baby.birthDate!);
    final days = diff.inDays;

    if (days < 30) {
      return '$days일';
    } else if (days < 365) {
      final months = days ~/ 30;
      return '$months개월';
    } else {
      final years = days ~/ 365;
      final months = (days % 365) ~/ 30;
      if (months == 0) return '$years살';
      return '$years살 $months개월';
    }
  }
}
