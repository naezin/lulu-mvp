import 'package:flutter/foundation.dart';

import '../../features/home/providers/sweet_spot_provider.dart'
    show SweetSpotState;

/// Sweet Spot calculation result model
///
/// Output of SweetSpotCalculator, consumed by UI layer.
/// [progress] is NOT stored — calculated in real-time via [calculateProgress].
///
/// Reference information: Wake Window values are parenting reference guidelines,
/// not individual diagnostic criteria.
/// Sources: Mindell(2016), Paruthi/AASM(2016), Taking Cara Babies, Huckleberry
@immutable
class SweetSpotResult {
  final String babyId;
  final int correctedAgeMonths;
  final SweetSpotState state;
  final WakeWindowRange wakeWindow;
  final DateTime? lastWakeTime;
  final DateTime minSleepTime;
  final DateTime maxSleepTime;
  final int napNumber;
  final int totalExpectedNaps;
  final bool isNightTime;
  final DateTime calculatedAt;
  final String stateMessageKey;

  const SweetSpotResult({
    required this.babyId,
    required this.correctedAgeMonths,
    required this.state,
    required this.wakeWindow,
    required this.lastWakeTime,
    required this.minSleepTime,
    required this.maxSleepTime,
    required this.napNumber,
    required this.totalExpectedNaps,
    required this.isNightTime,
    required this.calculatedAt,
    required this.stateMessageKey,
  });

  /// Real-time progress calculation (UX Designer feedback)
  ///
  /// Uses caller-provided [now] instead of DateTime.now() for testability.
  /// Progress bar moves in real-time by calling this with current time.
  double calculateProgress(DateTime now) {
    if (lastWakeTime == null) return 0.0;
    final elapsedMinutes = now.difference(lastWakeTime!).inMinutes;
    final midWindow = wakeWindow.midMinutes;
    if (midWindow <= 0) return 0.0;
    return (elapsedMinutes / midWindow).clamp(0.0, 1.2);
  }

  /// Minutes until Sweet Spot range start (real-time)
  int minMinutesUntil(DateTime now) {
    return minSleepTime.difference(now).inMinutes;
  }

  /// Minutes until Sweet Spot range end (real-time)
  int maxMinutesUntil(DateTime now) {
    return maxSleepTime.difference(now).inMinutes;
  }

  /// Legacy HomeProvider compat: minutesUntilSweetSpot (range midpoint)
  /// QA Lead feedback: map to mid, not min, to preserve range benefit
  int minutesUntilMid(DateTime now) {
    final midSleepTime = minSleepTime.add(
      Duration(
          minutes:
              maxSleepTime.difference(minSleepTime).inMinutes ~/ 2),
    );
    return midSleepTime.difference(now).inMinutes;
  }

  SweetSpotResult copyWith({
    String? babyId,
    int? correctedAgeMonths,
    SweetSpotState? state,
    WakeWindowRange? wakeWindow,
    DateTime? lastWakeTime,
    DateTime? minSleepTime,
    DateTime? maxSleepTime,
    int? napNumber,
    int? totalExpectedNaps,
    bool? isNightTime,
    DateTime? calculatedAt,
    String? stateMessageKey,
  }) {
    return SweetSpotResult(
      babyId: babyId ?? this.babyId,
      correctedAgeMonths: correctedAgeMonths ?? this.correctedAgeMonths,
      state: state ?? this.state,
      wakeWindow: wakeWindow ?? this.wakeWindow,
      lastWakeTime: lastWakeTime ?? this.lastWakeTime,
      minSleepTime: minSleepTime ?? this.minSleepTime,
      maxSleepTime: maxSleepTime ?? this.maxSleepTime,
      napNumber: napNumber ?? this.napNumber,
      totalExpectedNaps: totalExpectedNaps ?? this.totalExpectedNaps,
      isNightTime: isNightTime ?? this.isNightTime,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      stateMessageKey: stateMessageKey ?? this.stateMessageKey,
    );
  }
}

/// Wake Window range (min/max in minutes)
///
/// Reference information: Parenting reference guidelines.
/// Sources: Mindell(2016), AASM(2016), Taking Cara Babies, Huckleberry (MD reviewed)
@immutable
class WakeWindowRange {
  final int minMinutes;
  final int maxMinutes;

  const WakeWindowRange({
    required this.minMinutes,
    required this.maxMinutes,
  });

  int get midMinutes => (minMinutes + maxMinutes) ~/ 2;

  /// Apply correction factor (nap order)
  WakeWindowRange applyFactor(double factor) {
    return WakeWindowRange(
      minMinutes: (minMinutes * factor).round(),
      maxMinutes: (maxMinutes * factor).round(),
    );
  }
}

/// Personalized Wake Window data (Phase E learning engine will provide)
///
/// null = use literature table defaults.
/// Phase C-0: interface only, implementation in Phase E.
@immutable
class PersonalizedWakeWindow {
  /// Observed wake window range for this baby
  final WakeWindowRange observedRange;

  /// Blending ratio (0.0 = 100% literature, 1.0 = 100% observed)
  final double personalWeight;

  /// Days of observed data
  final int observedDays;

  /// Observed nap order correction factors
  /// null = use default correction constants
  final double? firstNapFactor;
  final double? lastNapFactor;

  /// Last nap quality data for adjustment (Phase E)
  final NapQualityFactor? lastNapQuality;

  /// Observed standard deviation of wake windows (minutes)
  final double? observedStdDev;

  const PersonalizedWakeWindow({
    required this.observedRange,
    required this.personalWeight,
    required this.observedDays,
    this.firstNapFactor,
    this.lastNapFactor,
    this.lastNapQuality,
    this.observedStdDev,
  });

  /// Empirical Bayes blending weight
  ///
  /// Combines sample density and consistency (stdDev) to determine
  /// how much to trust observed data vs literature.
  /// Returns 0.0 ~ 0.9 (never fully replaces literature).
  static double calculateWeight({
    required int samples,
    required double stdDev,
    required double baseRangeMid,
    int learningConstant = 20,
  }) {
    if (samples <= 0 || baseRangeMid <= 0) return 0.0;
    final densityWeight = samples / (samples + learningConstant);
    final normalizedStdDev = (stdDev / baseRangeMid).clamp(0.0, 1.0);
    final confidence = 1.0 - normalizedStdDev;
    return (densityWeight * confidence).clamp(0.0, 0.9);
  }
}

/// Nap quality adjustment factor
///
/// Short naps (< 30min) compress next wake window (baby still tired).
/// Long naps (> 60min) extend next wake window (well rested).
@immutable
class NapQualityFactor {
  final int lastNapDurationMinutes;

  const NapQualityFactor({required this.lastNapDurationMinutes});

  double get adjustmentFactor {
    if (lastNapDurationMinutes < 30) return 0.85;
    if (lastNapDurationMinutes > 60) return 1.10;
    return 1.0;
  }
}
