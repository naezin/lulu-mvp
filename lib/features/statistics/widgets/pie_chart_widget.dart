import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../models/weekly_statistics.dart';

/// 파이 차트 위젯
///
/// 작업 지시서 v1.2.1: fl_chart 사용, 접근성 테두리 적용
class PieChartWidget extends StatefulWidget {
  /// 파이 차트 섹션 데이터
  final List<PieSection> sections;

  /// 차트 크기
  final double size;

  /// 중앙 공간 반지름
  final double centerSpaceRadius;

  const PieChartWidget({
    super.key,
    required this.sections,
    this.size = 140,
    this.centerSpaceRadius = 30,
  });

  /// 수면 통계로 생성
  factory PieChartWidget.fromSleepStats({
    Key? key,
    required SleepStatistics stats,
    double size = 140,
  }) {
    return PieChartWidget(
      key: key,
      sections: [
        PieSection(
          value: stats.napRatio,
          label: '낮잠',
          color: LuluStatisticsColors.sleep.withValues(alpha: 0.7),
        ),
        PieSection(
          value: stats.nightRatio,
          label: '밤잠',
          color: LuluStatisticsColors.sleep,
        ),
      ],
      size: size,
    );
  }

  /// 수유 통계로 생성
  factory PieChartWidget.fromFeedingStats({
    Key? key,
    required FeedingStatistics stats,
    double size = 140,
  }) {
    return PieChartWidget(
      key: key,
      sections: [
        if (stats.breastMilkRatio > 0)
          PieSection(
            value: stats.breastMilkRatio,
            label: '모유',
            color: LuluStatisticsColors.feeding,
          ),
        if (stats.formulaRatio > 0)
          PieSection(
            value: stats.formulaRatio,
            label: '분유',
            color: LuluStatisticsColors.feeding.withValues(alpha: 0.7),
          ),
        if (stats.solidFoodRatio > 0)
          PieSection(
            value: stats.solidFoodRatio,
            label: '이유식',
            color: LuluStatisticsColors.feeding.withValues(alpha: 0.5),
          ),
      ],
      size: size,
    );
  }

  /// 기저귀 통계로 생성
  factory PieChartWidget.fromDiaperStats({
    Key? key,
    required DiaperStatistics stats,
    double size = 140,
  }) {
    return PieChartWidget(
      key: key,
      sections: [
        if (stats.wetRatio > 0)
          PieSection(
            value: stats.wetRatio,
            label: '소변',
            color: LuluStatisticsColors.diaper,
          ),
        if (stats.dirtyRatio > 0)
          PieSection(
            value: stats.dirtyRatio,
            label: '대변',
            color: LuluStatisticsColors.diaper.withValues(alpha: 0.7),
          ),
        if (stats.bothRatio > 0)
          PieSection(
            value: stats.bothRatio,
            label: '혼합',
            color: LuluStatisticsColors.diaper.withValues(alpha: 0.5),
          ),
      ],
      size: size,
    );
  }

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final accessibilityLabel = _buildAccessibilityLabel();

    return Semantics(
      label: accessibilityLabel,
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: PieChart(
            PieChartData(
              sections: _buildSections(),
              sectionsSpace: 2,
              centerSpaceRadius: widget.centerSpaceRadius,
              borderData: FlBorderData(show: false),
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
            ),
            swapAnimationDuration: const Duration(milliseconds: 250),
            swapAnimationCurve: Curves.easeOutCubic,
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    return widget.sections.asMap().entries.map((entry) {
      final index = entry.key;
      final section = entry.value;
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? 55.0 : 50.0;

      return PieChartSectionData(
        value: section.value * 100, // 비율을 퍼센트로 변환
        title: '${(section.value * 100).toInt()}%',
        color: section.color,
        radius: radius,
        titleStyle: LuluTextStyles.caption.copyWith(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        // v1.2.1: 접근성 테두리 추가 (색상 대비 보완)
        borderSide: BorderSide(
          color: LuluColors.surfaceDark,
          width: 2.0,
        ),
      );
    }).toList();
  }

  String _buildAccessibilityLabel() {
    final buffer = StringBuffer('비율 차트. ');

    for (final section in widget.sections) {
      final percent = (section.value * 100).toInt();
      buffer.write('${section.label} $percent퍼센트, ');
    }

    return buffer.toString().trimRight().replaceAll(RegExp(r', $'), '');
  }
}

/// 파이 차트 섹션 데이터
class PieSection {
  /// 비율 (0.0 ~ 1.0)
  final double value;

  /// 레이블
  final String label;

  /// 색상
  final Color color;

  const PieSection({
    required this.value,
    required this.label,
    required this.color,
  });
}
