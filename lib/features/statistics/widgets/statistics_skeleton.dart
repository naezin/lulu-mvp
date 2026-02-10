import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// 통계 스켈레톤 로딩 위젯
///
/// 작업 지시서 v1.2.1: 스켈레톤 로딩 UI
class StatisticsSkeleton extends StatelessWidget {
  const StatisticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: LuluColors.glassBorder,
      highlightColor: LuluColors.surfaceCard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 스켈레톤
            _buildSkeletonBox(width: 120, height: 24),

            const SizedBox(height: 16),

            // 대시보드 스켈레톤
            const DashboardSummarySkeleton(),

            const SizedBox(height: 16),

            // 차트 스켈레톤
            const ChartSkeleton(),

            const SizedBox(height: 16),

            // 인사이트 스켈레톤
            _buildSkeletonBox(width: double.infinity, height: 48),

            const SizedBox(height: 24),

            // 리포트 카드 스켈레톤
            _buildSkeletonBox(width: double.infinity, height: 60),
            const SizedBox(height: 8),
            _buildSkeletonBox(width: double.infinity, height: 60),
            const SizedBox(height: 8),
            _buildSkeletonBox(width: double.infinity, height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonBox({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LuluRadius.xs),
      ),
    );
  }
}

/// 대시보드 요약 스켈레톤
class DashboardSummarySkeleton extends StatelessWidget {
  const DashboardSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildCardSkeleton()),
        const SizedBox(width: 8),
        Expanded(child: _buildCardSkeleton()),
        const SizedBox(width: 8),
        Expanded(child: _buildCardSkeleton()),
      ],
    );
  }

  Widget _buildCardSkeleton() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
    );
  }
}

/// 차트 스켈레톤
class ChartSkeleton extends StatelessWidget {
  final double height;

  const ChartSkeleton({
    super.key,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
    );
  }
}

/// 오프라인 배너
class OfflineBanner extends StatelessWidget {
  final DateTime? lastSyncTime;

  const OfflineBanner({
    super.key,
    this.lastSyncTime,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: LuluColors.amberGoldBg,
      child: Row(
        children: [
          const Icon(
            LuluIcons.cloudOff,
            size: 16,
            color: LuluColors.amberGold,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.offlineModeLastSync(_formatTime(lastSyncTime, l10n)),
            style: const TextStyle(
              fontSize: 12,
              color: LuluColors.amberGold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time, S l10n) {
    if (time == null) return l10n.timeUnknown;

    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    return l10n.timeDaysAgo(diff.inDays);
  }
}

/// 에러 상태 뷰
class StatisticsErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const StatisticsErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LuluIcons.cloudOff,
              size: 48,
              color: LuluTextColors.tertiary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: LuluTextColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LuluIcons.refresh),
              label: Text(S.of(context)!.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: LuluColors.lavenderMist,
                foregroundColor: LuluColors.midnightNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty State 뷰
class StatisticsEmptyView extends StatelessWidget {
  final VoidCallback? onStartRecording;

  const StatisticsEmptyView({
    super.key,
    this.onStartRecording,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LuluIcons.insertChart,
              size: 64,
              color: LuluColors.glassBorder,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.statisticsEmptyTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: LuluTextColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.statisticsEmptyStartHint,
              style: TextStyle(
                fontSize: 14,
                color: LuluTextColors.secondary,
              ),
            ),
            if (onStartRecording != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onStartRecording,
                icon: const Icon(LuluIcons.add),
                label: Text(l10n.statisticsStartRecording),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LuluColors.lavenderMist,
                  side: BorderSide(color: LuluColors.lavenderMist),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
