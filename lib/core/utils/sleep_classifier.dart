import 'package:flutter/material.dart';

import '../../data/models/activity_model.dart';
import '../../data/models/baby_type.dart';

/// SleepClassifier v2 — Density-based sleep type auto classification
///
/// Determines nap vs night sleep based on the baby's own sleep pattern
/// using 24-hour sleep density histogram (clustering approach).
///
/// v2 key improvement over v1:
/// - v1: "longest sleep per day = night anchor" -> split night contamination
/// - v2: "densest sleep time zone = night window" -> split night chunks
///   naturally merge into the same density cluster
///
/// Design principles:
/// - Zero additional user input required
/// - Baby pattern-first, not fixed time zones
/// - Editable: classification result can be overridden in edit sheet
/// - Silent operation: no UI interruption
/// - Per-baby independent classification (multiple births)
///
/// Algorithm (pattern mode, 3+ days of data):
/// 1. Build 24h histogram: 48 bins (30-min each), weighted by recency
/// 2. Find peak bin (highest sleep density)
/// 3. Expand from peak: continuous bins above threshold (peak * 0.3)
/// 4. Result = NightWindow (startBin..endBin), handles midnight wrap
/// 5. Classify: startTime in NightWindow -> 'night', else -> 'nap'
///    Exception: nightWindow start + duration < 30min -> 'nap'
///
/// Cold start (0-2 days of data): fixed 21:00~06:00 range.
/// Rationale: with minimal data, fixed range is safer than duration-based
/// (avoids misclassifying long daytime naps as night sleep).
class SleepClassifier {
  // ============================================================
  // Constants
  // ============================================================

  /// Minimum days of completed sleep data for pattern-based classification
  static const int minDaysForPattern = 3;

  /// Number of recent days to analyze for histogram
  static const int lookbackDays = 14;

  /// Number of 30-minute bins in 24 hours
  static const int _binCount = 48;

  /// Night window expansion threshold (fraction of peak density)
  /// Bins with density >= peak * this value are included in night window
  static const double _expansionThreshold = 0.3;

  /// Minimum sleep duration (minutes) to count as night within window
  /// Prevents micro-sleeps (< 30min) from being classified as night
  static const int _minNightDurationMinutes = 30;

  /// Maximum gap bins allowed within night window expansion
  /// Allows up to 4 empty bins (2 hours) to bridge split night chunks
  /// e.g., 20:00-01:00 wake 01:00-03:00 sleep 03:00-06:00
  /// The 2h gap between chunks must be bridged for correct classification
  static const int _maxGapBins = 4;

  /// Cold start night range: 21:00 ~ 06:00
  static const int coldStartNightBegin = 21;
  static const int coldStartNightEnd = 6;

  // ============================================================
  // Public API (signatures unchanged from v1)
  // ============================================================

  /// Classify sleep type based on baby's recent sleep pattern
  ///
  /// [startTime] - when the sleep starts (required)
  /// [endTime] - when the sleep ends (null for "sleep now" mode)
  /// [recentSleepRecords] - completed sleep records from recent days
  /// [now] - current time (for testing, defaults to DateTime.now())
  ///
  /// Returns 'nap' or 'night'
  static String classify({
    required DateTime startTime,
    DateTime? endTime,
    required List<ActivityModel> recentSleepRecords,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    // Filter to completed sleep records with valid duration
    final completedSleeps = recentSleepRecords.where((a) {
      if (a.type != ActivityType.sleep) return false;
      if (a.endTime == null) return false;
      final duration = a.endTime!.difference(a.startTime).inMinutes;
      return duration > 0;
    }).toList();

    // Build night window from pattern
    final nightWindow = _buildNightWindow(completedSleeps, currentTime);

    if (nightWindow == null) {
      // Cold start: insufficient data -> fixed range
      return _classifyColdStart(startTime);
    }

    // Pattern-based classification using density cluster
    return _classifyWithWindow(startTime, endTime, nightWindow);
  }

  /// Check if classifier is in cold start mode
  /// (insufficient data for pattern-based classification)
  static bool isColdStart(List<ActivityModel> recentSleepRecords) {
    final now = DateTime.now();

    final completedSleeps = recentSleepRecords.where((a) {
      if (a.type != ActivityType.sleep) return false;
      if (a.endTime == null) return false;
      return a.endTime!.difference(a.startTime).inMinutes > 0;
    }).toList();

    return _buildNightWindow(completedSleeps, now) == null;
  }

  /// Read-time fallback: return existing sleep_type or classify if NULL
  ///
  /// For legacy records that have no sleep_type in their data map,
  /// this classifies using the full SleepClassifier algorithm.
  /// If [recentSleepRecords] is provided, uses pattern-based classification.
  /// Otherwise falls back to cold start (21:00~06:00).
  ///
  /// DB data is never modified — classification happens at read-time only.
  static String effectiveSleepType(
    ActivityModel activity, {
    List<ActivityModel> recentSleepRecords = const [],
  }) {
    // If sleep_type already exists in data, use it
    final existing = activity.data?['sleep_type'] as String?;
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    // Fallback: classify based on pattern or cold start
    return classify(
      startTime: activity.startTime,
      endTime: activity.endTime,
      recentSleepRecords: recentSleepRecords,
    );
  }

  /// Batch fallback: apply effectiveSleepType to a list of sleep activities
  ///
  /// Uses the same recentSleepRecords for all activities in the batch,
  /// avoiding redundant pattern extraction.
  static List<ActivityModel> applyFallbackSleepTypes(
    List<ActivityModel> activities, {
    List<ActivityModel> recentSleepRecords = const [],
  }) {
    return activities.map((activity) {
      if (activity.type != ActivityType.sleep) return activity;

      final existing = activity.data?['sleep_type'] as String?;
      if (existing != null && existing.isNotEmpty) return activity;

      // Classify and create new activity with sleep_type in data
      final classified = classify(
        startTime: activity.startTime,
        endTime: activity.endTime,
        recentSleepRecords: recentSleepRecords,
      );

      final updatedData = <String, dynamic>{
        ...?activity.data,
        'sleep_type': classified,
      };

      return activity.copyWith(data: updatedData);
    }).toList();
  }

  /// Get the current night window for debugging/display
  ///
  /// Returns null if in cold start mode.
  /// Returns NightWindow with startBin and endBin (0-47, 30-min bins).
  static NightWindow? getNightWindow(
    List<ActivityModel> recentSleepRecords, {
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final completedSleeps = recentSleepRecords.where((a) {
      if (a.type != ActivityType.sleep) return false;
      if (a.endTime == null) return false;
      return a.endTime!.difference(a.startTime).inMinutes > 0;
    }).toList();

    return _buildNightWindow(completedSleeps, currentTime);
  }

  // ============================================================
  // v2 Core: Density-based night window construction
  // ============================================================

  /// Build night window from sleep density histogram
  ///
  /// Returns null if insufficient data (< [minDaysForPattern] unique days).
  static NightWindow? _buildNightWindow(
    List<ActivityModel> completedSleeps,
    DateTime now,
  ) {
    final cutoff = now.subtract(const Duration(days: lookbackDays));

    // Count unique days with sleep data
    final uniqueDays = <String>{};
    final recentSleeps = <ActivityModel>[];

    for (final sleep in completedSleeps) {
      final localStart = sleep.startTime.toLocal();
      if (localStart.isBefore(cutoff)) continue;

      recentSleeps.add(sleep);
      final dateKey = '${localStart.year}-${localStart.month}-${localStart.day}';
      uniqueDays.add(dateKey);
    }

    if (uniqueDays.length < minDaysForPattern) {
      return null;
    }

    // Step 1: Build 24h histogram (48 bins × 30 min)
    final histogram = List<double>.filled(_binCount, 0.0);

    for (final sleep in recentSleeps) {
      final daysAgo = now.difference(sleep.startTime).inDays;
      // Recency weight: last 7 days = 1.0, 8-14 days = 0.5
      final weight = daysAgo <= 7 ? 1.0 : 0.5;

      _addSleepToBins(histogram, sleep.startTime.toLocal(),
          sleep.endTime!.toLocal(), weight);
    }

    // Step 2: Find peak bin
    double maxDensity = 0;
    int peakBin = 0;
    for (int i = 0; i < _binCount; i++) {
      if (histogram[i] > maxDensity) {
        maxDensity = histogram[i];
        peakBin = i;
      }
    }

    if (maxDensity == 0) return null;

    // Step 3: Expand from peak (circular, with gap tolerance)
    // Gap tolerance allows bridging empty bins (e.g., split night wake gaps)
    // up to _maxGapBins consecutive empty bins are allowed IF a dense bin
    // exists beyond the gap.
    final threshold = maxDensity * _expansionThreshold;

    // Expand left from peak
    int startBin = peakBin;
    int gapCount = 0;
    for (int i = 1; i < _binCount; i++) {
      final candidate = (peakBin - i + _binCount) % _binCount;
      if (histogram[candidate] >= threshold) {
        startBin = candidate;
        gapCount = 0; // Reset gap counter
      } else {
        gapCount++;
        if (gapCount > _maxGapBins) break;
        // In the middle of a gap: lookahead to see if density resumes
        // within remaining gap budget
        bool resumesAhead = false;
        for (int look = 1; look <= _maxGapBins - gapCount + 1; look++) {
          final ahead = (candidate - look + _binCount) % _binCount;
          if (histogram[ahead] >= threshold) {
            resumesAhead = true;
            break;
          }
        }
        if (!resumesAhead) break;
      }
    }

    // Expand right from peak
    int endBin = peakBin;
    gapCount = 0;
    for (int i = 1; i < _binCount; i++) {
      final candidate = (peakBin + i) % _binCount;
      if (histogram[candidate] >= threshold) {
        endBin = candidate;
        gapCount = 0;
      } else {
        gapCount++;
        if (gapCount > _maxGapBins) break;
        // In the middle of a gap: lookahead to see if density resumes
        bool resumesAhead = false;
        for (int look = 1; look <= _maxGapBins - gapCount + 1; look++) {
          final ahead = (candidate + look) % _binCount;
          if (histogram[ahead] >= threshold) {
            resumesAhead = true;
            break;
          }
        }
        if (!resumesAhead) break;
      }
    }

    return NightWindow(startBin: startBin, endBin: endBin);
  }

  /// Distribute sleep duration across histogram bins
  ///
  /// Each bin that the sleep overlaps gets [weight] added.
  /// Handles midnight crossing naturally via modular arithmetic.
  static void _addSleepToBins(
    List<double> histogram,
    DateTime localStart,
    DateTime localEnd,
    double weight,
  ) {
    int currentBin = _timeToBin(localStart);
    final endBin = _timeToBin(localEnd);

    // Safety: max 48 iterations (24 hours)
    int safety = 0;
    while (safety < _binCount) {
      histogram[currentBin] += weight;
      if (currentBin == endBin) break;
      currentBin = (currentBin + 1) % _binCount;
      safety++;
    }
  }

  /// Convert DateTime to bin index (0-47)
  static int _timeToBin(DateTime time) {
    return (time.hour * 2) + (time.minute >= 30 ? 1 : 0);
  }

  // ============================================================
  // Classification logic
  // ============================================================

  /// Classify using density-derived night window
  static String _classifyWithWindow(
    DateTime startTime,
    DateTime? endTime,
    NightWindow window,
  ) {
    final startBin = _timeToBin(startTime.toLocal());

    if (!window.contains(startBin)) {
      return 'nap';
    }

    // Start is within night window
    if (endTime != null) {
      final durationMinutes = endTime.difference(startTime).inMinutes;
      // Very short sleep in night window = micro-nap, not night
      if (durationMinutes < _minNightDurationMinutes) {
        return 'nap';
      }
      return 'night';
    }

    // "Sleep now" mode: start in night window -> assume night
    return 'night';
  }

  /// Cold start classification: fixed range 21:00 ~ 06:00
  ///
  /// Used when < 3 days of sleep data available.
  /// Fixed range is safer than duration-based for cold start because
  /// it avoids misclassifying long daytime naps as night sleep.
  static String _classifyColdStart(DateTime startTime) {
    final hour = startTime.toLocal().hour;
    if (hour >= coldStartNightBegin || hour < coldStartNightEnd) {
      return 'night';
    }
    return 'nap';
  }
}

/// Night window: the time zone where night sleep is concentrated
///
/// Represented as bin range (0-47, each bin = 30 minutes).
/// Handles midnight wrapping: if startBin > endBin, the window
/// wraps around midnight (e.g., startBin=40 [20:00] to endBin=12 [06:00]).
@immutable
class NightWindow {
  /// Start bin of night window (0-47)
  final int startBin;

  /// End bin of night window (0-47)
  final int endBin;

  const NightWindow({required this.startBin, required this.endBin});

  /// Check if a bin falls within this night window (circular)
  bool contains(int bin) {
    if (startBin <= endBin) {
      // No midnight wrap (e.g., 14:00 ~ 18:00)
      return bin >= startBin && bin <= endBin;
    } else {
      // Midnight wrap (e.g., 20:00 ~ 06:00)
      return bin >= startBin || bin <= endBin;
    }
  }

  /// Start hour (approximate, for display/debug)
  double get startHour => startBin * 0.5;

  /// End hour (approximate, for display/debug)
  double get endHour => (endBin + 1) * 0.5;

  /// Number of bins in this window
  int get binCount {
    if (startBin <= endBin) {
      return endBin - startBin + 1;
    } else {
      return (_binCount - startBin) + endBin + 1;
    }
  }

  static const int _binCount = 48;

  @override
  String toString() {
    final startH = (startBin ~/ 2).toString().padLeft(2, '0');
    final startM = (startBin % 2 == 0) ? '00' : '30';
    final endH = (endBin ~/ 2).toString().padLeft(2, '0');
    final endM = (endBin % 2 == 0) ? '00' : '30';
    return 'NightWindow($startH:$startM ~ $endH:$endM)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NightWindow &&
        other.startBin == startBin &&
        other.endBin == endBin;
  }

  @override
  int get hashCode => Object.hash(startBin, endBin);
}
