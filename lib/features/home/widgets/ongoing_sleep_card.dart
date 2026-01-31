import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../providers/home_provider.dart';
import '../../record/providers/ongoing_sleep_provider.dart';

/// 홈 화면 진행 중 수면 카드
///
/// QA-03: 수면 시작 후 홈 화면에서 진행 상태 표시 및 종료 가능
class OngoingSleepCard extends StatelessWidget {
  const OngoingSleepCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OngoingSleepProvider>(
      builder: (context, provider, _) {
        if (!provider.hasSleepInProgress) {
          return const SizedBox.shrink();
        }

        return _OngoingSleepCardContent(provider: provider);
      },
    );
  }
}

class _OngoingSleepCardContent extends StatelessWidget {
  final OngoingSleepProvider provider;

  const _OngoingSleepCardContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    final babyName = provider.ongoingSleep?.babyName ?? '아기';
    final sleepType = provider.ongoingSleep?.sleepType == 'night' ? '밤잠' : '낮잠';

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.lg,
        vertical: LuluSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LuluActivityColors.sleep.withValues(alpha: 0.15),
            LuluActivityColors.sleep.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: LuluActivityColors.sleep.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEndSleepDialog(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 상단: 아이콘 + 정보
                Row(
                  children: [
                    // 애니메이션 아이콘
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: LuluActivityColors.sleep.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          LuluIcons.sleep,
                          size: 28,
                          color: LuluActivityColors.sleep,
                        ),
                      ),
                    ),
                    const SizedBox(width: LuluSpacing.lg),
                    // 정보
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$babyName $sleepType 중',
                            style: LuluTextStyles.titleSmall.copyWith(
                              color: LuluTextColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            provider.formattedElapsedTime,
                            style: LuluTextStyles.displaySmall.copyWith(
                              color: LuluActivityColors.sleep,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: LuluSpacing.lg),

                // 종료 버튼
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: LuluActivityColors.sleep,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bedtime_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '탭하여 수면 종료',
                        style: LuluTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEndSleepDialog(BuildContext context) {
    final provider = context.read<OngoingSleepProvider>();
    final babyName = provider.ongoingSleep?.babyName ?? '아기';
    final startTime = provider.sleepStartTime;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LuluColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          '수면을 종료할까요?',
          style: LuluTextStyles.titleMedium.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('아기', babyName),
            const SizedBox(height: 8),
            _buildInfoRow('시작', _formatTime(startTime!)),
            const SizedBox(height: 8),
            _buildInfoRow('종료', _formatTime(DateTime.now())),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LuluActivityColors.sleepBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: LuluActivityColors.sleep,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '총 수면: ${provider.formattedElapsedTime}',
                    style: LuluTextStyles.titleMedium.copyWith(
                      color: LuluActivityColors.sleep,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              '취소',
              style: LuluTextStyles.labelLarge.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final savedActivity = await provider.endSleep();

              // HomeProvider에 활동 추가하여 UI 갱신
              if (savedActivity != null && context.mounted) {
                context.read<HomeProvider>().addActivity(savedActivity);
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(LuluIcons.sleep, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          '수면 기록이 저장되었어요',
                          style: LuluTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: LuluActivityColors.sleep,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LuluActivityColors.sleep,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('종료'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
        Text(
          value,
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return DateFormat('a h:mm', 'ko').format(dt);
  }
}
