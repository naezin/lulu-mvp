import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/constants/animation_constants.dart';
import '../../../data/models/growth_measurement_model.dart';
import '../data/fenton_data.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../data/growth_data_cache.dart';

/// 통합 성장 차트 위젯
///
/// Fenton (22-50주) / WHO (0-24개월) 자동 전환
/// 체중/신장/두위 3개 지표 지원
class GrowthChart extends StatefulWidget {
  final GrowthChartType chartType;
  final GrowthMetric metric;
  final Gender gender;
  final List<GrowthMeasurementModel> measurements;
  final int? startWeek; // Fenton용
  final int? endWeek;
  final int? startMonth; // WHO용
  final int? endMonth;
  final double? currentWeekOrMonth;
  final bool showAnimation;
  final VoidCallback? onPointTap;

  const GrowthChart({
    super.key,
    required this.chartType,
    required this.metric,
    required this.gender,
    required this.measurements,
    this.startWeek,
    this.endWeek,
    this.startMonth,
    this.endMonth,
    this.currentWeekOrMonth,
    this.showAnimation = true,
    this.onPointTap,
  });

  @override
  State<GrowthChart> createState() => _GrowthChartState();
}

class _GrowthChartState extends State<GrowthChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: LuluAnimations.chart,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: LuluAnimations.chartCurve),
    );

    if (widget.showAnimation) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.lg),
      decoration: BoxDecoration(
        color: LuluColors.deepBlue,
        borderRadius: BorderRadius.circular(LuluRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          _buildHeader(),
          const SizedBox(height: LuluSpacing.lg),

          // 차트 영역
          SizedBox(
            height: 250,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _GrowthChartPainter(
                    chartType: widget.chartType,
                    metric: widget.metric,
                    gender: widget.gender,
                    measurements: widget.measurements,
                    progress: _animation.value,
                    startWeek: widget.startWeek ?? 22,
                    endWeek: widget.endWeek ?? 50,
                    startMonth: widget.startMonth ?? 0,
                    endMonth: widget.endMonth ?? 24,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: LuluSpacing.md),

          // 범례
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(widget.metric.icon, size: 20, color: LuluTextColors.primary),
        const SizedBox(width: LuluSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context)!.growthChartTitleWithMetric(widget.metric.localizedLabel(S.of(context)!)),
              style: LuluTextStyles.titleSmall.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
            Text(
              widget.chartType.localizedDescription(S.of(context)!),
              style: LuluTextStyles.caption.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          color: LuluColors.lavenderBorder,
          label: '3-97%',
        ),
        const SizedBox(width: LuluSpacing.lg),
        _LegendItem(
          color: LuluColors.lavenderMedium,
          label: '10-90%',
        ),
        const SizedBox(width: LuluSpacing.lg),
        _LegendItem(
          color: LuluColors.champagneGold,
          label: S.of(context)!.growthChartLegendMedian,
        ),
        const SizedBox(width: LuluSpacing.lg),
        _LegendItem(
          color: LuluColors.lavenderMist,
          label: S.of(context)!.growthChartLegendMeasured,
          isPoint: true,
        ),
      ],
    );
  }
}

class _GrowthChartPainter extends CustomPainter {
  final GrowthChartType chartType;
  final GrowthMetric metric;
  final Gender gender;
  final List<GrowthMeasurementModel> measurements;
  final double progress;
  final int startWeek;
  final int endWeek;
  final int startMonth;
  final int endMonth;

  _GrowthChartPainter({
    required this.chartType,
    required this.metric,
    required this.gender,
    required this.measurements,
    required this.progress,
    required this.startWeek,
    required this.endWeek,
    required this.startMonth,
    required this.endMonth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTWH(40, 10, size.width - 60, size.height - 40);

    // 배경 그리드
    _drawGrid(canvas, chartRect);

    // 백분위 영역
    _drawPercentileAreas(canvas, chartRect);

    // 백분위 라인
    _drawPercentileLines(canvas, chartRect);

    // 측정값 포인트
    _drawMeasurementPoints(canvas, chartRect);

    // 축 라벨
    _drawAxisLabels(canvas, chartRect, size);
  }

  void _drawGrid(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = LuluColors.surfaceElevatedBorder
      ..strokeWidth = 1;

    // 수평선
    for (int i = 0; i <= 4; i++) {
      final y = rect.top + (rect.height / 4) * i;
      canvas.drawLine(
        Offset(rect.left, y),
        Offset(rect.right, y),
        paint,
      );
    }

    // 수직선
    final divisions = chartType == GrowthChartType.fenton ? 7 : 6;
    for (int i = 0; i <= divisions; i++) {
      final x = rect.left + (rect.width / divisions) * i;
      canvas.drawLine(
        Offset(x, rect.top),
        Offset(x, rect.bottom),
        paint,
      );
    }
  }

  void _drawPercentileAreas(Canvas canvas, Rect rect) {
    if (!GrowthDataCache.instance.isInitialized) return;

    // 3-97% 영역
    final area3to97Paint = Paint()
      ..color = LuluColors.lavenderMist.withValues(alpha: 0.1 * progress)
      ..style = PaintingStyle.fill;

    // 10-90% 영역
    final area10to90Paint = Paint()
      ..color = LuluColors.lavenderMist.withValues(alpha: 0.15 * progress)
      ..style = PaintingStyle.fill;

    // 영역 그리기 (간략화된 버전)
    final path3to97 = Path()
      ..addRect(Rect.fromLTRB(
        rect.left,
        rect.top + rect.height * 0.05,
        rect.right,
        rect.bottom - rect.height * 0.05,
      ));

    final path10to90 = Path()
      ..addRect(Rect.fromLTRB(
        rect.left,
        rect.top + rect.height * 0.15,
        rect.right,
        rect.bottom - rect.height * 0.15,
      ));

    canvas.drawPath(path3to97, area3to97Paint);
    canvas.drawPath(path10to90, area10to90Paint);
  }

  void _drawPercentileLines(Canvas canvas, Rect rect) {
    // 50% 중앙선
    final p50Paint = Paint()
      ..color = LuluColors.champagneGold.withValues(alpha: progress)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerY = rect.top + rect.height / 2;
    final path = Path()
      ..moveTo(rect.left, centerY)
      ..lineTo(rect.left + rect.width * progress, centerY);

    canvas.drawPath(path, p50Paint);

    // 다른 백분위 라인 (3, 10, 90, 97)
    final otherPaint = Paint()
      ..color = LuluColors.lavenderMist.withValues(alpha: 0.4 * progress)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final percentilePositions = [0.05, 0.15, 0.85, 0.95];
    for (final pos in percentilePositions) {
      final y = rect.top + rect.height * pos;
      canvas.drawLine(
        Offset(rect.left, y),
        Offset(rect.left + rect.width * progress, y),
        otherPaint,
      );
    }
  }

  void _drawMeasurementPoints(Canvas canvas, Rect rect) {
    if (measurements.isEmpty) return;

    final pointPaint = Paint()
      ..color = LuluColors.lavenderMist
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = LuluColors.lavenderMist.withValues(alpha: 0.7 * progress)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 측정값을 좌표로 변환 (간략화)
    final points = <Offset>[];
    for (int i = 0; i < measurements.length; i++) {
      final measurement = measurements[i];
      final value = _getMeasurementValue(measurement);
      if (value == null) continue;

      // X 좌표: 시간 기반
      final xRatio = (i + 1) / (measurements.length + 1);
      final x = rect.left + rect.width * xRatio;

      // Y 좌표: 값 기반 (간략화된 정규화)
      final yRatio = _normalizeValue(value);
      final y = rect.bottom - rect.height * yRatio;

      points.add(Offset(x, y));
    }

    // 연결선 그리기
    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // 포인트 그리기
    for (final point in points) {
      canvas.drawCircle(
        point,
        6 * progress,
        pointPaint,
      );
      // 흰색 테두리
      canvas.drawCircle(
        point,
        6 * progress,
        Paint()
          ..color = LuluColors.midnightNavy
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawAxisLabels(Canvas canvas, Rect rect, Size size) {
    final textStyle = TextStyle(
      color: LuluTextColors.tertiary,
      fontSize: 10,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // X축 라벨
    if (chartType == GrowthChartType.fenton) {
      final weeks = [22, 26, 30, 34, 38, 42, 46, 50];
      for (int i = 0; i < weeks.length; i++) {
        final x = rect.left + (rect.width / 7) * i;
        textPainter.text = TextSpan(text: '${weeks[i]}w', style: textStyle);
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, rect.bottom + 5),
        );
      }
    } else {
      final months = [0, 4, 8, 12, 16, 20, 24];
      for (int i = 0; i < months.length; i++) {
        final x = rect.left + (rect.width / 6) * i;
        textPainter.text = TextSpan(text: '${months[i]}m', style: textStyle);
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, rect.bottom + 5),
        );
      }
    }

    // Y축 라벨 (단위)
    textPainter.text = TextSpan(text: metric.unit, style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, Offset(5, rect.top - 5));
  }

  double? _getMeasurementValue(GrowthMeasurementModel measurement) {
    return switch (metric) {
      GrowthMetric.weight => measurement.weightKg,
      GrowthMetric.length => measurement.lengthCm,
      GrowthMetric.headCircumference => measurement.headCircumferenceCm,
    };
  }

  double _normalizeValue(double value) {
    // 간략화된 정규화 (실제 구현에서는 차트 데이터 기반)
    return switch (metric) {
      GrowthMetric.weight => (value / 15).clamp(0.0, 1.0),
      GrowthMetric.length => ((value - 40) / 60).clamp(0.0, 1.0),
      GrowthMetric.headCircumference => ((value - 30) / 20).clamp(0.0, 1.0),
    };
  }

  @override
  bool shouldRepaint(covariant _GrowthChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.measurements != measurements;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isPoint;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isPoint = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPoint)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          )
        else
          Container(
            width: 16,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(LuluRadius.xxs),
            ),
          ),
        const SizedBox(width: 4),
        Text(
          label,
          style: LuluTextStyles.caption.copyWith(
            color: LuluTextColors.tertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
