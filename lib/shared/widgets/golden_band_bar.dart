import 'package:flutter/material.dart';
import '../../core/design_system/lulu_colors.dart';

/// Golden Band Progress Bar (C-5 Sweet Spot Card)
///
/// CustomPainter-based progress bar that shows:
/// - Track (full width grey background)
/// - Golden band (optimal sleep zone within the track)
/// - Position marker (current position indicator)
/// - Calibrating stripe pattern (when learning)
///
/// Design spec:
/// - Bar height: 12dp, round 6dp
/// - Band: inside bar, round 4dp
/// - Marker: 14dp circle above bar, elevation 2dp
/// - Animation: marker movement only (200ms ease)
class GoldenBandBar extends StatelessWidget {
  /// Current position on the timeline (0.0 ~ 1.2)
  /// 0.0 = wake time, 1.0 = end of zone, >1.0 = past zone
  final double progress;

  /// Golden zone start position (0.0 ~ 1.0)
  final double bandStart;

  /// Golden zone end position (0.0 ~ 1.0)
  final double bandEnd;

  /// Baby theme color (full opacity)
  final Color themeColor;

  /// Baby theme color light variant (15%)
  final Color themeColorLight;

  /// Baby theme color strong variant (80%)
  final Color themeColorStrong;

  /// Whether the bar is in calibrating state
  final bool isCalibrating;

  /// Whether the marker is in the golden zone
  final bool isInZone;

  /// Whether past the zone (grey out)
  final bool isAfterZone;

  const GoldenBandBar({
    super.key,
    required this.progress,
    required this.bandStart,
    required this.bandEnd,
    required this.themeColor,
    required this.themeColorLight,
    required this.themeColorStrong,
    this.isCalibrating = false,
    this.isInZone = false,
    this.isAfterZone = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: CustomPaint(
        size: const Size(double.infinity, 28),
        painter: _GoldenBandPainter(
          progress: progress,
          bandStart: bandStart,
          bandEnd: bandEnd,
          themeColor: themeColor,
          themeColorLight: themeColorLight,
          themeColorStrong: themeColorStrong,
          isCalibrating: isCalibrating,
          isInZone: isInZone,
          isAfterZone: isAfterZone,
        ),
      ),
    );
  }
}

class _GoldenBandPainter extends CustomPainter {
  final double progress;
  final double bandStart;
  final double bandEnd;
  final Color themeColor;
  final Color themeColorLight;
  final Color themeColorStrong;
  final bool isCalibrating;
  final bool isInZone;
  final bool isAfterZone;

  static const double _barHeight = 12.0;
  static const double _barRadius = 6.0;
  static const double _bandRadius = 4.0;
  static const double _markerRadius = 7.0;
  static const double _markerBorderWidth = 2.0;

  _GoldenBandPainter({
    required this.progress,
    required this.bandStart,
    required this.bandEnd,
    required this.themeColor,
    required this.themeColorLight,
    required this.themeColorStrong,
    required this.isCalibrating,
    required this.isInZone,
    required this.isAfterZone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barTop = size.height - _barHeight;
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, barTop, size.width, _barHeight),
      const Radius.circular(_barRadius),
    );

    // 1. Draw track background
    final trackPaint = Paint()..color = LuluColors.surfaceElevated;
    canvas.drawRRect(barRect, trackPaint);

    if (isCalibrating) {
      _drawCalibratingStripes(canvas, size, barTop);
    } else {
      // 2. Draw golden band
      _drawGoldenBand(canvas, size, barTop);

      // 3. Draw marker
      _drawMarker(canvas, size);
    }
  }

  void _drawGoldenBand(Canvas canvas, Size size, double barTop) {
    final bandLeft = size.width * bandStart.clamp(0.0, 1.0);
    final bandRight = size.width * bandEnd.clamp(0.0, 1.0);
    final bandWidth = bandRight - bandLeft;

    if (bandWidth <= 0) return;

    final bandColor = isAfterZone
        ? LuluColors.surfaceElevatedBorder
        : (isInZone ? themeColor : themeColorStrong);

    final bandPaint = Paint()..color = bandColor;

    final bandRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bandLeft, barTop + 2, bandWidth, _barHeight - 4),
      const Radius.circular(_bandRadius),
    );
    canvas.drawRRect(bandRect, bandPaint);

    // Glow effect when in zone
    if (isInZone && !isAfterZone) {
      final glowPaint = Paint()
        ..color = themeColorLight
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(bandRect, glowPaint);
      // Re-draw band on top of glow
      canvas.drawRRect(bandRect, bandPaint);
    }
  }

  void _drawMarker(Canvas canvas, Size size) {
    final clampedProgress = progress.clamp(0.0, 1.2);
    final markerX = (size.width * clampedProgress).clamp(
      _markerRadius,
      size.width - _markerRadius,
    );
    final markerCenterY = size.height - _barHeight - _markerRadius + 2;

    // Marker shadow
    final shadowPaint = Paint()
      ..color = LuluColors.shadowBlack
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(
      Offset(markerX, markerCenterY + 1),
      _markerRadius,
      shadowPaint,
    );

    // Marker fill (white)
    final markerFillPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(markerX, markerCenterY),
      _markerRadius,
      markerFillPaint,
    );

    // Marker border
    final Color borderColor;
    if (isAfterZone) {
      borderColor = LuluTextColors.tertiary;
    } else if (isInZone) {
      borderColor = themeColor;
    } else {
      borderColor = LuluColors.lavenderBorder;
    }

    final markerBorderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _markerBorderWidth;
    canvas.drawCircle(
      Offset(markerX, markerCenterY),
      _markerRadius - _markerBorderWidth / 2,
      markerBorderPaint,
    );

    // Inner dot when in zone
    if (isInZone && !isAfterZone) {
      final dotPaint = Paint()..color = themeColor;
      canvas.drawCircle(
        Offset(markerX, markerCenterY),
        3,
        dotPaint,
      );
    }
  }

  void _drawCalibratingStripes(Canvas canvas, Size size, double barTop) {
    // Save canvas state for clipping
    canvas.save();

    // Clip to bar shape
    final barPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, barTop, size.width, _barHeight),
        const Radius.circular(_barRadius),
      ));
    canvas.clipPath(barPath);

    // Draw diagonal stripes
    final stripePaint = Paint()
      ..color = LuluColors.surfaceElevatedBorder
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const stripeSpacing = 8.0;
    final stripeCount = (size.width / stripeSpacing).ceil() + 5;

    for (int i = -stripeCount; i < stripeCount; i++) {
      final x = i * stripeSpacing;
      canvas.drawLine(
        Offset(x, barTop - 2),
        Offset(x + _barHeight + 4, barTop + _barHeight + 2),
        stripePaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_GoldenBandPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        bandStart != oldDelegate.bandStart ||
        bandEnd != oldDelegate.bandEnd ||
        themeColor != oldDelegate.themeColor ||
        isCalibrating != oldDelegate.isCalibrating ||
        isInZone != oldDelegate.isInZone ||
        isAfterZone != oldDelegate.isAfterZone;
  }
}
