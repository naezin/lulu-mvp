import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_icons.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// Sweet Spot calculation Provider
///
/// Sprint 21 Phase 2-3: Extracted from HomeProvider
/// - Calculates optimal sleep timing based on last wake time
/// - Age-based recommended awake time (corrected age for preterm)
/// - Single-direction data flow: HomeProvider → SweetSpotProvider.recalculate()
class SweetSpotProvider extends ChangeNotifier {
  // ========================================
  // State
  // ========================================

  /// Sweet Spot state
  SweetSpotState _sweetSpotState = SweetSpotState.unknown;
  SweetSpotState get sweetSpotState => _sweetSpotState;

  /// Minutes until Sweet Spot
  int _minutesUntilSweetSpot = 0;
  int get minutesUntilSweetSpot => _minutesUntilSweetSpot;

  /// Recommended sleep time
  DateTime? _recommendedSleepTime;
  DateTime? get recommendedSleepTime => _recommendedSleepTime;

  /// Sweet Spot progress (0.0 ~ 1.2)
  double _sweetSpotProgress = 0.0;
  double get sweetSpotProgress => _sweetSpotProgress;

  /// Night time flag (18:00-05:59)
  bool get isNightTime {
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
  void recalculate({
    required DateTime? lastSleepEndTime,
    required int? babyAgeInMonths,
  }) {
    if (lastSleepEndTime == null || babyAgeInMonths == null) {
      if (_sweetSpotState != SweetSpotState.unknown) {
        _sweetSpotState = SweetSpotState.unknown;
        _minutesUntilSweetSpot = 0;
        _recommendedSleepTime = null;
        _sweetSpotProgress = 0.0;
        notifyListeners();
      }
      return;
    }

    final recommendedAwakeTime = _getRecommendedAwakeTime(babyAgeInMonths);
    final elapsedMinutes = DateTime.now().difference(lastSleepEndTime).inMinutes;

    final newMinutes = recommendedAwakeTime - elapsedMinutes;
    final newRecommendedTime = lastSleepEndTime.add(
      Duration(minutes: recommendedAwakeTime),
    );
    final newProgress = (elapsedMinutes / recommendedAwakeTime).clamp(0.0, 1.2);

    // Determine state
    final SweetSpotState newState;
    if (newMinutes > 30) {
      newState = SweetSpotState.tooEarly;
    } else if (newMinutes > 0) {
      newState = SweetSpotState.approaching;
    } else if (newMinutes > -15) {
      newState = SweetSpotState.optimal;
    } else {
      newState = SweetSpotState.overtired;
    }

    // Guard: only notify if changed
    if (_sweetSpotState == newState &&
        _minutesUntilSweetSpot == newMinutes &&
        _recommendedSleepTime == newRecommendedTime) {
      return;
    }

    _sweetSpotState = newState;
    _minutesUntilSweetSpot = newMinutes;
    _recommendedSleepTime = newRecommendedTime;
    _sweetSpotProgress = newProgress;
    notifyListeners();
  }

  /// Reset all state
  void reset() {
    _sweetSpotState = SweetSpotState.unknown;
    _minutesUntilSweetSpot = 0;
    _recommendedSleepTime = null;
    _sweetSpotProgress = 0.0;
    notifyListeners();
  }

  // ========================================
  // Age-based recommended awake time
  // ========================================

  /// Recommended awake time in minutes by age
  int _getRecommendedAwakeTime(int ageInMonths) {
    if (ageInMonths < 1) return 45; // Newborn: 45min
    if (ageInMonths < 2) return 60; // 1 month: 1h
    if (ageInMonths < 3) return 75; // 2 months: 1h 15m
    if (ageInMonths < 4) return 90; // 3 months: 1h 30m
    if (ageInMonths < 6) return 120; // 4-5 months: 2h
    if (ageInMonths < 9) return 150; // 6-8 months: 2h 30m
    if (ageInMonths < 12) return 180; // 9-11 months: 3h
    return 210; // 12+ months: 3h 30m
  }
}

/// Sweet Spot state enum
enum SweetSpotState {
  /// Unknown
  unknown,

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
      SweetSpotState.tooEarly => l10n.sweetSpotStateLabelTooEarly,
      SweetSpotState.approaching => l10n.sweetSpotStateLabelApproaching,
      SweetSpotState.optimal => l10n.sweetSpotStateLabelOptimal,
      SweetSpotState.overtired => l10n.sweetSpotStateLabelOvertired,
    };
  }

  IconData get icon {
    return switch (this) {
      SweetSpotState.unknown => LuluIcons.info,
      SweetSpotState.tooEarly => LuluIcons.sun,
      SweetSpotState.approaching => LuluIcons.sleep,
      SweetSpotState.optimal => LuluIcons.moon,
      SweetSpotState.overtired => LuluIcons.warning,
    };
  }
}
