import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/onboarding_data_service.dart';
import '../providers/onboarding_provider.dart';
import 'onboarding_screen.dart' show OnboardingCompleteCallback;

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
                Icons.check_rounded,
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
                    borderRadius: BorderRadius.circular(16),
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
    if (provider.babyCount == 1) {
      return '${provider.babies.first.name}의 육아 기록을\n시작할 준비가 되었어요';
    } else {
      final names = provider.babies.map((b) => b.name).join(', ');
      return '$names의 육아 기록을\n시작할 준비가 되었어요';
    }
  }

  Future<void> _handleComplete(BuildContext context) async {
    final provider = context.read<OnboardingProvider>();

    try {
      final result = await provider.completeOnboarding();

      // 디버그 로그
      debugPrint('✅ [Onboarding] Family created: ${result.family.id}');
      for (final baby in result.babies) {
        debugPrint('✅ [Onboarding] Baby created: ${baby.name}');
      }

      // SharedPreferences에 데이터 저장 (BUG-001 fix)
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
        borderRadius: BorderRadius.circular(20),
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

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.babyAvatarColors[index % AppTheme.babyAvatarColors.length];

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
        // 조산아 배지
        if (baby.isPreterm)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.warningSoft.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${baby.gestationalWeeks}주',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.warningSoft,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
    );
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
