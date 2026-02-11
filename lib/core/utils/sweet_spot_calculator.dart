import '../../data/models/sweet_spot_result.dart';
import '../../features/home/providers/sweet_spot_provider.dart'
    show SweetSpotState;

/// Sweet Spot calculation engine (standalone class)
///
/// Pure calculation logic extracted from SweetSpotProvider.
/// DateTime.now() NEVER called internally — all times injected via parameters.
///
/// Reference information:
/// Wake Window values are multi-source parenting reference guidelines.
/// Not based on academic RCTs but practitioner consensus + observational trends.
/// Sources: Mindell(2016), Paruthi/AASM(2016), Taking Cara Babies,
///          Huckleberry(MD reviewed), Cleveland Clinic, Halo Sleep(AAP cited)
class SweetSpotCalculator {
  // ============================================================
  // Nap order correction constants
  // ============================================================
  //
  // Observational trend: "first wake window is shortest, last is longest"
  // Sources: Taking Cara Babies, Baby Sleep Site, multiple sleep consultants
  //          Dr. Craig Canapari(Yale): "a four month old will go down at
  //          1.5 hours for the first nap but 2-2.5 hours for the next nap"
  //
  // Note: -10%/+15% values have no exact academic basis.
  //       Approximations quantifying observational trends.
  //       Phase E personalization engine will adjust with real data.
  //
  // Sleep Specialist feedback: no hardcoding → configurable constants

  /// First nap correction factor (default: 0.9 = -10%)
  final double firstNapFactor;

  /// Last nap correction factor (default: 1.15 = +15%)
  final double lastNapFactor;

  const SweetSpotCalculator({
    this.firstNapFactor = 0.9,
    this.lastNapFactor = 1.15,
  });

  // ============================================================
  // Sleep regression period damping
  // ============================================================
  //
  // During regression months, personalization weight is reduced
  // because sleep patterns become temporarily unstable.
  // Sources: Mindell(2016), Taking Cara Babies

  static const List<int> _regressionMonths = [4, 8, 12, 18];
  static const double _regressionDamping = 0.80;

  // ============================================================
  // Calibration threshold
  // ============================================================
  //
  // Minimum completed sleep records (today) before normal prediction.
  // Below this count → calibrating state (still shows literature-based
  // prediction, but UI indicates learning phase).
  // Newborns sleep 4-5x/day, so threshold of 3 is achievable daily.

  static const int _calibrationThreshold = 3;

  static bool isRegressionPeriod(int correctedAgeMonths) {
    return _regressionMonths.contains(correctedAgeMonths);
  }

  // ============================================================
  // 13-stage Wake Window table (literature consensus)
  // ============================================================
  //
  // Cross-verified sources:
  //   - Taking Cara Babies (cites Mindell 2016)
  //   - Huckleberry (MD reviewed by Gina M. Jansheski, FAAP)
  //   - Cleveland Clinic (Kristin Barrett, MD)
  //   - Halo Sleep (cites AAP 2023)
  //   - v1 sweet_spot_calculator.dart (13-stage granularity)
  //
  // 7-9 stage sources interpolated to 13 stages based on v1.
  // Interpolated ranges(*) will be calibrated with real data in Phase E.
  //
  // Change log:
  //   - 0~2wk lower: v1 35min → 30min (literature consensus 30-60min)

  static const List<_AgeWakeWindow> _wakeWindowTable = [
    // age upper(mo),  min(min),  max(min)   source/notes
    _AgeWakeWindow(0.5, 30, 60), // 0~2wk: consensus 30-60min
    _AgeWakeWindow(1.0, 40, 60), // 2~4wk: interpolated(*)
    _AgeWakeWindow(2.0, 60, 90), // 1~2mo: consensus 60-90min
    _AgeWakeWindow(3.0, 60, 90), // 2~3mo: consensus 60-90min
    _AgeWakeWindow(4.0, 75, 120), // 3~4mo: consensus 75-120min
    _AgeWakeWindow(5.0, 90, 135), // 4~5mo: interpolated(*)
    _AgeWakeWindow(6.0, 105, 150), // 5~6mo: interpolated(*)
    _AgeWakeWindow(7.0, 120, 180), // 6~7mo: consensus 120-180min
    _AgeWakeWindow(9.0, 150, 210), // 7~9mo: consensus 150-210min
    _AgeWakeWindow(11.0, 165, 225), // 9~11mo: interpolated(*)
    _AgeWakeWindow(12.0, 180, 240), // 11~12mo: consensus 180-240min
    _AgeWakeWindow(18.0, 210, 300), // 12~18mo: interpolated(*)
    _AgeWakeWindow(99.0, 240, 360), // 18mo+: consensus 240-360min
  ];

  // ============================================================
  // Age-based expected nap count
  // ============================================================
  //
  // Data Scientist feedback: totalExpectedNaps logic clarified
  // Sources: AASM 2016, National Sleep Foundation, Huckleberry

  static int getExpectedNapCount(int correctedAgeMonths) {
    if (correctedAgeMonths < 3) return 4; // 0~3mo: 4-5 → 4 baseline
    if (correctedAgeMonths < 5) return 3; // 3~5mo: 3-4 → 3 baseline
    if (correctedAgeMonths < 8) return 3; // 5~8mo: 2-3 → 3 baseline
    if (correctedAgeMonths < 13) return 2; // 8~13mo: 2
    if (correctedAgeMonths < 18) return 2; // 13~18mo: 1-2 → 2 baseline
    return 1; // 18mo+: 1
  }

  // ============================================================
  // Core method: Calculate current Sweet Spot
  // ============================================================

  /// Calculate Sweet Spot for current moment
  ///
  /// [now]: current time (injected, not DateTime.now() — testable)
  /// [completedSleepRecords]: today's completed sleep count (null = skip calibration check, backward compat)
  /// [personalizedWindow]: Phase E personalization data (null = literature table)
  SweetSpotResult calculate({
    required String babyId,
    required int correctedAgeMonths,
    required DateTime? lastWakeTime,
    required DateTime now,
    int? completedSleepRecords,
    int? currentNapNumber,
    int? totalExpectedNaps,
    PersonalizedWakeWindow? personalizedWindow,
  }) {
    // No sleep record → unknown
    if (lastWakeTime == null) {
      return _unknownResult(babyId, correctedAgeMonths, now);
    }

    // Calibrating: fewer than threshold completed sleep records today
    // Still provides literature-based prediction (no blank screen)
    if (completedSleepRecords != null &&
        completedSleepRecords < _calibrationThreshold) {
      return _calibratingResult(
        babyId: babyId,
        correctedAgeMonths: correctedAgeMonths,
        lastWakeTime: lastWakeTime,
        now: now,
        completedSleepRecords: completedSleepRecords,
        currentNapNumber: currentNapNumber,
        totalExpectedNaps: totalExpectedNaps,
        personalizedWindow: personalizedWindow,
      );
    }

    final expectedNaps =
        totalExpectedNaps ?? getExpectedNapCount(correctedAgeMonths);
    final napNum = currentNapNumber ?? 1;

    // Wake Window range: literature or personalized blending
    final baseRange = _getWakeWindowRange(correctedAgeMonths);
    final effectiveRange = _blendWithPersonalized(
        baseRange, personalizedWindow, correctedAgeMonths);

    // Nap order correction
    final napCorrectedRange = _applyNapCorrection(
      effectiveRange,
      napNum,
      expectedNaps,
      personalizedWindow,
    );

    // Nap quality factor adjustment
    final correctedRange = _applyNapQualityFactor(
      napCorrectedRange,
      personalizedWindow?.lastNapQuality,
    );

    // Sweet Spot time range
    final minSleepTime =
        lastWakeTime.add(Duration(minutes: correctedRange.minMinutes));
    final maxSleepTime =
        lastWakeTime.add(Duration(minutes: correctedRange.maxMinutes));

    // State determination
    final state = _determineState(now, minSleepTime, maxSleepTime);

    // Night sleep判定 (18:00~05:59)
    final hour = now.hour;
    final isNight = hour >= 18 || hour < 6;

    // State-specific i18n message key
    final messageKey = _getStateMessageKey(state, isNight);

    return SweetSpotResult(
      babyId: babyId,
      correctedAgeMonths: correctedAgeMonths,
      state: state,
      wakeWindow: correctedRange,
      lastWakeTime: lastWakeTime,
      minSleepTime: minSleepTime,
      maxSleepTime: maxSleepTime,
      napNumber: napNum,
      totalExpectedNaps: expectedNaps,
      isNightTime: isNight,
      calculatedAt: now,
      stateMessageKey: messageKey,
    );
  }

  // ============================================================
  // Daily nap schedule calculation
  // ============================================================

  /// Generate full-day nap timeline from morning wake time
  ///
  /// Used in Phase C-5 card redesign for "full day plan" display.
  /// Naps exceeding nightBedtime are not generated.
  /// (Data Scientist feedback)
  List<SweetSpotResult> calculateDailyNapSchedule({
    required String babyId,
    required int correctedAgeMonths,
    required DateTime morningWakeTime,
    required DateTime now,
    PersonalizedWakeWindow? personalizedWindow,
    DateTime? nightBedtime,
  }) {
    final expectedNaps = getExpectedNapCount(correctedAgeMonths);
    final bedtime = nightBedtime ??
        DateTime(
          morningWakeTime.year,
          morningWakeTime.month,
          morningWakeTime.day,
          19,
          0,
        );

    final results = <SweetSpotResult>[];
    var currentWakeTime = morningWakeTime;

    for (int nap = 1; nap <= expectedNaps; nap++) {
      final result = calculate(
        babyId: babyId,
        correctedAgeMonths: correctedAgeMonths,
        lastWakeTime: currentWakeTime,
        now: now,
        currentNapNumber: nap,
        totalExpectedNaps: expectedNaps,
        personalizedWindow: personalizedWindow,
      );

      // Stop if nap exceeds bedtime (Data Scientist feedback)
      if (result.minSleepTime.isAfter(bedtime)) break;

      results.add(result);

      // Estimate next wake time: mid sleep time + estimated nap duration
      final midSleepTime = result.minSleepTime.add(
        Duration(
            minutes: result.wakeWindow.midMinutes -
                result.wakeWindow.minMinutes),
      );
      final estimatedNapDuration =
          _getEstimatedNapDuration(correctedAgeMonths);
      currentWakeTime =
          midSleepTime.add(Duration(minutes: estimatedNapDuration));
    }

    return results;
  }

  // ============================================================
  // Internal methods
  // ============================================================

  /// Look up Wake Window range by age
  WakeWindowRange _getWakeWindowRange(int correctedAgeMonths) {
    // Clamp negative corrected age (extreme preterm) to 0
    // Data Scientist feedback
    final safeAge = correctedAgeMonths.clamp(0, 99).toDouble();

    for (final entry in _wakeWindowTable) {
      if (safeAge < entry.ageUpperBoundMonths) {
        return WakeWindowRange(
          minMinutes: entry.minMinutes,
          maxMinutes: entry.maxMinutes,
        );
      }
    }
    // fallback: last entry
    return const WakeWindowRange(minMinutes: 240, maxMinutes: 360);
  }

  /// Blend with personalized data
  WakeWindowRange _blendWithPersonalized(
    WakeWindowRange baseRange,
    PersonalizedWakeWindow? personalized,
    int correctedAgeMonths,
  ) {
    if (personalized == null || personalized.personalWeight <= 0) {
      return baseRange;
    }

    var w = personalized.personalWeight.clamp(0.0, 1.0);

    // Regression period damping: reduce trust in observed data
    if (isRegressionPeriod(correctedAgeMonths)) {
      w *= _regressionDamping;
    }
    final blendedMin = (baseRange.minMinutes * (1 - w) +
            personalized.observedRange.minMinutes * w)
        .round();
    final blendedMax = (baseRange.maxMinutes * (1 - w) +
            personalized.observedRange.maxMinutes * w)
        .round();

    // Safety clamp: within 75%~125% of literature range
    final lowerBound = (baseRange.minMinutes * 0.75).round();
    final upperBound = (baseRange.maxMinutes * 1.25).round();

    final safeMin = blendedMin.clamp(lowerBound, upperBound);
    final safeMax = blendedMax.clamp(lowerBound, upperBound);

    return WakeWindowRange(
      minMinutes: safeMin < safeMax ? safeMin : safeMax,
      maxMinutes: safeMax > safeMin ? safeMax : safeMin,
    );
  }

  /// Apply nap order correction
  WakeWindowRange _applyNapCorrection(
    WakeWindowRange base,
    int napNumber,
    int totalNaps,
    PersonalizedWakeWindow? personalized,
  ) {
    if (totalNaps <= 1) return base; // 1 nap: no correction

    // Personalized factors take priority, then defaults
    final firstFact = personalized?.firstNapFactor ?? firstNapFactor;
    final lastFact = personalized?.lastNapFactor ?? lastNapFactor;

    if (napNumber == 1) {
      return base.applyFactor(firstFact);
    } else if (napNumber >= totalNaps) {
      return base.applyFactor(lastFact);
    }
    return base; // Middle naps: no correction
  }

  /// Apply nap quality adjustment
  ///
  /// Short previous nap → compress wake window (baby still tired).
  /// Long previous nap → extend wake window (well rested).
  WakeWindowRange _applyNapQualityFactor(
    WakeWindowRange base,
    NapQualityFactor? napQuality,
  ) {
    if (napQuality == null) return base;
    return base.applyFactor(napQuality.adjustmentFactor);
  }

  /// Determine state
  SweetSpotState _determineState(
    DateTime now,
    DateTime minSleepTime,
    DateTime maxSleepTime,
  ) {
    if (now.isBefore(
        minSleepTime.subtract(const Duration(minutes: 30)))) {
      return SweetSpotState.tooEarly;
    }
    if (now.isBefore(minSleepTime)) {
      return SweetSpotState.approaching;
    }
    if (now.isBefore(maxSleepTime) ||
        now.isAtSameMomentAs(maxSleepTime)) {
      return SweetSpotState.optimal;
    }
    return SweetSpotState.overtired;
  }

  /// State-specific i18n message key
  String _getStateMessageKey(SweetSpotState state, bool isNight) {
    switch (state) {
      case SweetSpotState.unknown:
        return 'sweetSpotUnknown';
      case SweetSpotState.calibrating:
        return 'sweetSpotCalibrating';
      case SweetSpotState.tooEarly:
        return isNight
            ? 'sweetSpotTooEarlyNight'
            : 'sweetSpotTooEarlyDay';
      case SweetSpotState.approaching:
        return isNight
            ? 'sweetSpotApproachingNight'
            : 'sweetSpotApproachingDay';
      case SweetSpotState.optimal:
        return isNight
            ? 'sweetSpotOptimalNight'
            : 'sweetSpotOptimalDay';
      case SweetSpotState.overtired:
        return 'sweetSpotOvertired';
    }
  }

  /// Helper: unknown result
  SweetSpotResult _unknownResult(
      String babyId, int ageMonths, DateTime now) {
    return SweetSpotResult(
      babyId: babyId,
      correctedAgeMonths: ageMonths,
      state: SweetSpotState.unknown,
      wakeWindow:
          const WakeWindowRange(minMinutes: 0, maxMinutes: 0),
      lastWakeTime: null,
      minSleepTime: now,
      maxSleepTime: now,
      napNumber: 0,
      totalExpectedNaps: 0,
      isNightTime: now.hour >= 18 || now.hour < 6,
      calculatedAt: now,
      stateMessageKey: 'sweetSpotUnknown',
    );
  }

  /// Helper: calibrating result (literature-based prediction with calibrating state)
  ///
  /// Provides the same calculation as normal mode, but marks state as
  /// calibrating so UI can show learning progress.
  /// This avoids blank screens while data is being collected.
  SweetSpotResult _calibratingResult({
    required String babyId,
    required int correctedAgeMonths,
    required DateTime lastWakeTime,
    required DateTime now,
    required int completedSleepRecords,
    int? currentNapNumber,
    int? totalExpectedNaps,
    PersonalizedWakeWindow? personalizedWindow,
  }) {
    final expectedNaps =
        totalExpectedNaps ?? getExpectedNapCount(correctedAgeMonths);
    final napNum = currentNapNumber ?? 1;

    // Literature-based calculation (same as normal path)
    final baseRange = _getWakeWindowRange(correctedAgeMonths);
    final effectiveRange = _blendWithPersonalized(
        baseRange, personalizedWindow, correctedAgeMonths);
    final napCorrectedRange = _applyNapCorrection(
      effectiveRange,
      napNum,
      expectedNaps,
      personalizedWindow,
    );
    final correctedRange = _applyNapQualityFactor(
      napCorrectedRange,
      personalizedWindow?.lastNapQuality,
    );

    final minSleepTime =
        lastWakeTime.add(Duration(minutes: correctedRange.minMinutes));
    final maxSleepTime =
        lastWakeTime.add(Duration(minutes: correctedRange.maxMinutes));

    final hour = now.hour;
    final isNight = hour >= 18 || hour < 6;

    return SweetSpotResult(
      babyId: babyId,
      correctedAgeMonths: correctedAgeMonths,
      state: SweetSpotState.calibrating,
      wakeWindow: correctedRange,
      lastWakeTime: lastWakeTime,
      minSleepTime: minSleepTime,
      maxSleepTime: maxSleepTime,
      napNumber: napNum,
      totalExpectedNaps: expectedNaps,
      isNightTime: isNight,
      calculatedAt: now,
      stateMessageKey: _getStateMessageKey(SweetSpotState.calibrating, isNight),
      completedSleepRecords: completedSleepRecords,
      calibrationTarget: _calibrationThreshold,
    );
  }

  /// Estimated average nap duration by age (for daily schedule)
  int _getEstimatedNapDuration(int correctedAgeMonths) {
    if (correctedAgeMonths < 3) return 30;
    if (correctedAgeMonths < 6) return 45;
    if (correctedAgeMonths < 12) return 60;
    return 90;
  }
}

/// Internal table entry (private)
class _AgeWakeWindow {
  final double ageUpperBoundMonths;
  final int minMinutes;
  final int maxMinutes;

  const _AgeWakeWindow(
      this.ageUpperBoundMonths, this.minMinutes, this.maxMinutes);
}
