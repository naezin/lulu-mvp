import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../models/weekly_statistics.dart';

/// 주간 막대 차트 위젯
///
/// 작업 지시서 v1.2.1: fl_chart 사용, RepaintBoundary 적용
class WeeklyBarChart extends StatelessWidget {
  /// 요일별 데이터 (월~일, 7개)
  final List<double> data;

  /// 차트 색상
  final Color barColor;

  /// 리포트 타입 (null이면 수면 기본)
  final ReportType? reportType;

  /// 하이라이트할 요일 인덱스 (null이면 없음)
  final int? highlightIndex;

  /// 막대 탭 콜백
  final ValueChanged<int>? onBarTap;

  /// 차트 높이
  final double height;

  const WeeklyBarChart({
    super.key,
    required this.data,
    this.barColor = LuluStatisticsColors.sleep,
    this.reportType,
    this.highlightIndex,
    this.onBarTap,
    this.height = 180,
  });

  /// 리포트 타입으로 생성
  factory WeeklyBarChart.fromReportType({
    Key? key,
    required ReportType type,
    required List<double> data,
    int? highlightIndex,
    ValueChanged<int>? onBarTap,
    double height = 180,
  }) {
    Color color;
    switch (type) {
      case ReportType.sleep:
        color = LuluStatisticsColors.sleep;
      case ReportType.feeding:
        color = LuluStatisticsColors.feeding;
      case ReportType.diaper:
        color = LuluStatisticsColors.diaper;
      case ReportType.crying:
        color = LuluStatisticsColors.crying;
    }

    return WeeklyBarChart(
      key: key,
      data: data,
      barColor: color,
      reportType: type,
      highlightIndex: highlightIndex,
      onBarTap: onBarTap,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;
    final dayNames = [
      l10n.dayNameMon, l10n.dayNameTue, l10n.dayNameWed,
      l10n.dayNameThu, l10n.dayNameFri, l10n.dayNameSat, l10n.dayNameSun,
    ];

    // 접근성 레이블 생성
    final accessibilityLabel = _buildAccessibilityLabel(l10n);

    return Semantics(
      label: accessibilityLabel,
      child: RepaintBoundary(
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _calculateMaxY(),
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => LuluColors.surfaceCard,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        l10n.chartTooltipDayValue(
                          dayNames[group.x.toInt()],
                          rod.toY.toStringAsFixed(1),
                        ),
                        LuluTextStyles.caption.copyWith(
                          color: LuluTextColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent &&
                        response != null &&
                        response.spot != null) {
                      onBarTap?.call(response.spot!.touchedBarGroupIndex);
                    }
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) =>
                          _buildBottomTitle(value, meta, dayNames),
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: _buildLeftTitle,
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateInterval(),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: LuluColors.glassBorder,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(),
              ),
              swapAnimationDuration: const Duration(milliseconds: 250),
              swapAnimationCurve: Curves.easeOutCubic,
            ),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(7, (index) {
      final isHighlighted = highlightIndex == index;
      final value = index < data.length ? data[index] : 0.0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: isHighlighted ? barColor : barColor.withValues(alpha: 0.6),
            width: 24,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            borderSide: BorderSide(
              color: LuluColors.surfaceDark,
              width: 1,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBottomTitle(double value, TitleMeta meta, List<String> dayNames) {
    final index = value.toInt();
    if (index < 0 || index >= 7) return const SizedBox.shrink();

    final isHighlighted = highlightIndex == index;

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        dayNames[index],
        style: LuluTextStyles.caption.copyWith(
          color: isHighlighted ? barColor : LuluTextColors.secondary,
          fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildLeftTitle(double value, TitleMeta meta) {
    // 정수만 표시
    if (value != value.roundToDouble()) return const SizedBox.shrink();

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        value.toInt().toString(),
        style: LuluTextStyles.caption.copyWith(
          color: LuluTextColors.tertiary,
        ),
      ),
    );
  }

  double _calculateMaxY() {
    if (data.isEmpty) return 20;
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    // 최대값보다 20% 여유 있게
    return (maxValue * 1.2).ceilToDouble();
  }

  double _calculateInterval() {
    final maxY = _calculateMaxY();
    if (maxY <= 10) return 2;
    if (maxY <= 20) return 5;
    return 10;
  }

  String _buildAccessibilityLabel(S l10n) {
    final dayNames = [
      l10n.dayNameMonFull, l10n.dayNameTueFull, l10n.dayNameWedFull,
      l10n.dayNameThuFull, l10n.dayNameFriFull, l10n.dayNameSatFull, l10n.dayNameSunFull,
    ];
    final buffer = StringBuffer('${l10n.chartAccessibilityLast7Days} ');

    for (int i = 0; i < data.length && i < 7; i++) {
      buffer.write('${dayNames[i]} ${data[i].toStringAsFixed(1)}, ');
    }

    if (data.isNotEmpty) {
      final average = data.reduce((a, b) => a + b) / data.length;
      buffer.write(l10n.chartAccessibilityAverage(average.toStringAsFixed(1)));
    }

    return buffer.toString();
  }
}
