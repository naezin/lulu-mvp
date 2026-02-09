import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../models/together_data.dart';
import 'pie_chart_widget.dart';

/// 함께 보기 뷰 위젯
///
/// 작업 지시서 v1.2.1: 다태아 함께 보기 (비교 X)
/// ⚠️ "더 높다/낮다" 표현 금지, "패턴이 달라요" 표현 사용
class TogetherView extends StatelessWidget {
  /// 함께 보기 데이터
  final TogetherData data;

  const TogetherView({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;

    if (!data.hasMultipleBabies) {
      return Center(
        child: Text(
          l10n.togetherViewNeedMultipleBabies,
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            l10n.statisticsTogetherViewTitle,
            style: LuluTextStyles.titleMedium,
          ),

          const SizedBox(height: 16),

          // 요약 카드 (나란히)
          _buildSummaryComparison(context),

          const SizedBox(height: 24),

          // 수면 패턴 (나란히)
          _buildSleepPatternSection(context),

          const SizedBox(height: 16),

          // 인사이트
          _buildInsight(context),
        ],
      ),
    );
  }

  Widget _buildSummaryComparison(BuildContext context) {
    final l10n = S.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.babies.map((baby) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: baby == data.babies.last ? 0 : 8,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LuluColors.surfaceCard,
              borderRadius: BorderRadius.circular(LuluRadius.sm),
              border: Border.all(color: LuluColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 아기 이름 + 교정연령
                Text(
                  baby.babyName,
                  style: LuluTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (baby.correctedAgeDays != null)
                  Text(
                    S.of(context)!.statisticsCorrectedAge(baby.correctedAgeDays!),
                    style: LuluTextStyles.caption.copyWith(
                      color: LuluTextColors.secondary,
                    ),
                  ),

                const SizedBox(height: 12),

                // 수면
                _buildStatRow(
                  icon: LuluIcons.sleepOutlined,
                  color: LuluStatisticsColors.sleep,
                  value: '${baby.statistics.sleep.dailyAverageHours.toStringAsFixed(1)}h',
                ),

                const SizedBox(height: 8),

                // 수유
                _buildStatRow(
                  icon: LuluIcons.feedingOutlined,
                  color: LuluStatisticsColors.feeding,
                  value: '${baby.statistics.feeding.dailyAverageCount.toStringAsFixed(1)}${l10n.unitTimes}',
                ),

                const SizedBox(height: 8),

                // 기저귀
                _buildStatRow(
                  icon: LuluIcons.diaperOutlined,
                  color: LuluStatisticsColors.diaper,
                  value: '${baby.statistics.diaper.dailyAverageCount.toStringAsFixed(1)}${l10n.unitTimes}',
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required Color color,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          value,
          style: LuluTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepPatternSection(BuildContext context) {
    final l10n = S.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목
        Row(
          children: [
            Icon(
              LuluIcons.sleepOutlined,
              size: 20,
              color: LuluStatisticsColors.sleep,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.sleepPattern,
              style: LuluTextStyles.titleSmall,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 파이차트 나란히
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.babies.map((baby) {
            return Expanded(
              child: Column(
                children: [
                  // 아기 이름
                  Text(
                    baby.babyName,
                    style: LuluTextStyles.caption.copyWith(
                      color: LuluTextColors.secondary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 파이차트
                  Center(
                    child: PieChartWidget.fromSleepStats(
                      stats: baby.statistics.sleep,
                      napLabel: l10n.sleepTypeNap,
                      nightLabel: l10n.sleepTypeNight,
                      size: 100,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 비율 텍스트
                  Text(
                    l10n.napRatioPercent((baby.statistics.sleep.napRatio * 100).toInt()),
                    style: LuluTextStyles.caption,
                  ),
                  Text(
                    l10n.nightRatioPercent((baby.statistics.sleep.nightRatio * 100).toInt()),
                    style: LuluTextStyles.caption,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInsight(BuildContext context) {
    if (data.babies.length < 2) return const SizedBox.shrink();

    final l10n = S.of(context)!;
    final baby1 = data.babies[0];
    final baby2 = data.babies[1];

    // ⚠️ "더 높다/낮다" 표현 금지, "패턴이 달라요" 표현 사용
    final insight1 = baby1.statistics.sleep.napRatio > 0.3
        ? l10n.insightNapRatioHigh
        : l10n.insightNightRatioHigh;

    final insight2 = baby2.statistics.sleep.napRatio > 0.3
        ? l10n.insightNapRatioHigh
        : l10n.insightNightRatioHigh;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(LuluRadius.xs),
        border: Border.all(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LuluIcons.tip,
            size: 20,
            color: Color(0xFFFBBF24),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.insightPatternDifference(
                baby1.babyName,
                insight1,
                baby2.babyName,
                insight2,
              ),
              style: LuluTextStyles.bodySmall.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
