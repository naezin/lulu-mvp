import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/lulu_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/onboarding_data_service.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/utils/sga_calculator.dart';
import '../../../../l10n/generated/app_localizations.dart' show S;
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
    final l10n = S.of(context);

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
                    const Color(0xCC5FB37B), // successSoft 80%
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
                  l10n?.onboardingCompletionTitle ?? '',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  _getCompletionMessage(provider, l10n),
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
                    : Text(
                        l10n?.buttonStart ?? '',
                        style: const TextStyle(
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

  String _getCompletionMessage(OnboardingProvider provider, S? l10n) {
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
        return l10n?.onboardingCompletionPreterm(babyName) ?? '';
      } else if (hasSGA) {
        return l10n?.onboardingCompletionSGA(babyName) ?? '';
      }
      return l10n?.onboardingCompletionReady(babyName) ?? '';
    } else {
      final names = babies.map((b) => b.name).join(', ');

      if (hasPreterm) {
        return l10n?.onboardingCompletionPreterm(names) ?? '';
      } else if (hasSGA) {
        return l10n?.onboardingCompletionSGA(names) ?? '';
      }
      return l10n?.onboardingCompletionReady(names) ?? '';
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

      // SharedPreferences + Supabase에 데이터 저장
      // prefs에 Supabase familyId가 저장됨 (로컬 UUID 대신)
      await OnboardingDataService.instance.saveOnboardingData(
        family: result.family,
        babies: result.babies,
      );

      // 콜백에서 Supabase 재로드 수행 (메모리 전체 갱신)
      if (widget.onCompleteWithData != null) {
        widget.onCompleteWithData!(result.family, result.babies);
      } else {
        widget.onComplete?.call();
      }
    } catch (e) {
      if (!context.mounted) return;

      debugPrint('[ERR] [CompletionScreen] Onboarding completion failed: $e');
      final errorL10n = S.of(context);
      AppToast.showText(errorL10n?.onboardingCompletionError(errorL10n.errorUnknown) ?? '');
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
    final l10n = S.of(context);
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
                _getBabyInfo(l10n),
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
    final l10n = S.of(context);
    switch (classification) {
      case BirthClassification.preterm:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: LuluStatusColors.warningLight,
            borderRadius: BorderRadius.circular(LuluRadius.xs),
          ),
          child: Text(
            l10n?.gestationalWeeksShort(baby.gestationalWeeks ?? 0) ?? '',
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
            color: LuluColors.tealLight,
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
                l10n?.growthTracking ?? '',
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

  String _getBabyInfo(S? l10n) {
    if (baby.birthDate == null) return '';

    final now = DateTime.now();
    final diff = now.difference(baby.birthDate!);
    final days = diff.inDays;

    if (days < 30) {
      return l10n?.ageInfoDays(days) ?? '';
    } else if (days < 365) {
      final months = days ~/ 30;
      return l10n?.ageInfoMonths(months) ?? '';
    } else {
      final years = days ~/ 365;
      final months = (days % 365) ~/ 30;
      if (months == 0) return l10n?.ageInfoYears(years) ?? '';
      return l10n?.ageInfoYearsMonths(years, months) ?? '';
    }
  }
}
