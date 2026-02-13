import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_icons.dart';
import '../../../core/utils/sweet_spot_calculator.dart';
import '../../../data/models/sweet_spot_result.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// Sweet Spot calculation Provider
///
/// Sprint 21 Phase 2-3: Extracted from HomeProvider
/// Sprint 22 Phase C-0: Internal logic delegated to SweetSpotCalculator
///
/// - State management wrapper for SweetSpotCalculator
/// - Single-direction data flow: HomeProvider → SweetSpotProvider.recalculate()
/// - All getter signatures preserved for UI compatibility
class SweetSpotProvider extends ChangeNotifier {
  // ========================================
  // Calculator engine
  // ========================================

  final SweetSpotCalculator _calculator = const SweetSpotCalculator();

  // ========================================
  // State
  // ========================================

  /// Calculation result (full range data)
  SweetSpotResult? _sweetSpotResult;
  SweetSpotResult? get sweetSpotResult => _sweetSpotResult;

  /// Sweet Spot state (getter compat — delegates to result)
  SweetSpotState get sweetSpotState =>
      _sweetSpotResult?.state ?? SweetSpotState.unknown;

  /// Minutes until Sweet Spot (getter compat — delegates to result mid)
  int get minutesUntilSweetSpot {
    if (_sweetSpotResult == null) return 0;
    return _sweetSpotResult!.minutesUntilMid(DateTime.now());
  }

  /// Recommended sleep time (getter compat — maps to min sleep time)
  DateTime? get recommendedSleepTime => _sweetSpotResult?.minSleepTime;

  /// Sweet Spot progress (0.0 ~ 1.2) (getter compat — real-time)
  double get sweetSpotProgress {
    if (_sweetSpotResult == null) return 0.0;
    return _sweetSpotResult!.calculateProgress(DateTime.now());
  }

  /// Night time flag (18:00-05:59) (getter compat — delegates to result)
  bool get isNightTime {
    if (_sweetSpotResult != null) return _sweetSpotResult!.isNightTime;
    final hour = DateTime.now().hour;
    return hour >= 18 || hour < 6;
  }

  // ========================================
  // Recalculate (single-direction from HomeProvider)
  // ========================================

  /// Recalculate Sweet Spot based on last sleep end time and baby age
  ///
  /// Called by HomeProvider when:
  /// - Activities change (add/remove/update/set)
  /// - Baby selection changes
  /// - Data refresh completes
  ///
  /// [lastSleepEndTime]: end time of the last sleep activity (null = unknown)
  /// [babyAgeInMonths]: effective age in months (corrected for preterm)
  /// [completedSleepRecords]: today's completed sleep count (null = skip calibration)
  void recalculate({
    required DateTime? lastSleepEndTime,
    required int? babyAgeInMonths,
    int? completedSleepRecords,
    int? currentNapNumber,
  }) {
    if (lastSleepEndTime == null || babyAgeInMonths == null) {
      if (_sweetSpotResult != null) {
        _sweetSpotResult = null;
        notifyListeners();
      }
      return;
    }

    final now = DateTime.now();

    final result = _calculator.calculate(
      babyId: '',
      correctedAgeMonths: babyAgeInMonths,
      lastWakeTime: lastSleepEndTime,
      now: now,
      completedSleepRecords: completedSleepRecords,
      currentNapNumber: currentNapNumber,
    );

    // Guard: only notify if state changed
    final oldState = _sweetSpotResult?.state;
    final oldMinutes = _sweetSpotResult?.minutesUntilMid(now);
    final newMinutes = result.minutesUntilMid(now);

    if (oldState == result.state && oldMinutes == newMinutes) {
      // Update result silently (for progress changes)
      _sweetSpotResult = result;
      return;
    }

    _sweetSpotResult = result;
    notifyListeners();
  }

  /// Reset all state
  void reset() {
    _sweetSpotResult = null;
    notifyListeners();
  }
}

/// Sweet Spot state enum
enum SweetSpotState {
  /// Unknown (no sleep records at all)
  unknown,

  /// Calibrating (1~2 sleep records today, learning pattern)
  calibrating,

  /// Still early (not tired yet)
  tooEarly,

  /// Approaching optimal time
  approaching,

  /// Optimal time now
  optimal,

  /// Overtired
  overtired,
}

extension SweetSpotStateExtension on SweetSpotState {
  /// Localized label (i18n)
  String localizedLabel(S l10n) {
    return switch (this) {
      SweetSpotState.unknown => l10n.sweetSpotStateLabelUnknown,
      SweetSpotState.calibrating => l10n.sweetSpotStateLabelCalibrating,
      SweetSpotState.tooEarly => l10n.sweetSpotStateLabelTooEarly,
      SweetSpotState.approaching => l10n.sweetSpotStateLabelApproaching,
      SweetSpotState.optimal => l10n.sweetSpotStateLabelOptimal,
      SweetSpotState.overtired => l10n.sweetSpotStateLabelOvertired,
    };
  }

  IconData get icon {
    return switch (this) {
      SweetSpotState.unknown => LuluIcons.info,
      SweetSpotState.calibrating => LuluIcons.sleep,
      SweetSpotState.tooEarly => LuluIcons.sun,
      SweetSpotState.approaching => LuluIcons.sleep,
      SweetSpotState.optimal => LuluIcons.moon,
      SweetSpotState.overtired => LuluIcons.warning,
    };
  }
}
