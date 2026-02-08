import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
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
    final l10n = S.of(context);

    if (!data.hasMultipleBabies) {
      return Center(
        child: Text(
          '아기 2명 이상일 때 함께 보기가 가능해요',
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
            l10n?.statisticsTogetherViewTitle ?? 'Together View',
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
                if (baby.correctedAgeLabel != null)
                  Text(
                    baby.correctedAgeLabel!,
                    style: LuluTextStyles.caption.copyWith(
                      color: LuluTextColors.secondary,
                    ),
                  ),

                const SizedBox(height: 12),

                // 수면
                _buildStatRow(
                  icon: Icons.bedtime_outlined,
                  color: LuluStatisticsColors.sleep,
                  value: '${baby.statistics.sleep.dailyAverageHours.toStringAsFixed(1)}h',
                ),

                const SizedBox(height: 8),

                // 수유
                _buildStatRow(
                  icon: Icons.local_drink_outlined,
                  color: LuluStatisticsColors.feeding,
                  value: '${baby.statistics.feeding.dailyAverageCount.toStringAsFixed(1)}회',
                ),

                const SizedBox(height: 8),

                // 기저귀
                _buildStatRow(
                  icon: Icons.baby_changing_station_outlined,
                  color: LuluStatisticsColors.diaper,
                  value: '${baby.statistics.diaper.dailyAverageCount.toStringAsFixed(1)}회',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목
        Row(
          children: [
            Icon(
              Icons.bedtime_outlined,
              size: 20,
              color: LuluStatisticsColors.sleep,
            ),
            const SizedBox(width: 8),
            Text(
              '수면 패턴',
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
                      size: 100,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 비율 텍스트
                  Text(
                    '낮잠 ${(baby.statistics.sleep.napRatio * 100).toInt()}%',
                    style: LuluTextStyles.caption,
                  ),
                  Text(
                    '밤잠 ${(baby.statistics.sleep.nightRatio * 100).toInt()}%',
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

    final baby1 = data.babies[0];
    final baby2 = data.babies[1];

    // ⚠️ "더 높다/낮다" 표현 금지, "패턴이 달라요" 표현 사용
    String insight1;
    String insight2;

    if (baby1.statistics.sleep.napRatio > 0.3) {
      insight1 = '낮잠 비율이 높아요';
    } else {
      insight1 = '밤잠 비율이 높아요';
    }

    if (baby2.statistics.sleep.napRatio > 0.3) {
      insight2 = '낮잠 비율이 높아요';
    } else {
      insight2 = '밤잠 비율이 높아요';
    }

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
            Icons.lightbulb_outline,
            size: 20,
            color: Color(0xFFFBBF24),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${baby1.babyName}은 $insight1,\n${baby2.babyName}이는 $insight2\n(패턴이 달라요)',
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
