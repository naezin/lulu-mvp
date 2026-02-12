import '../../data/models/activity_model.dart';
import '../../data/models/baby_type.dart';

/// SleepClassifier - C-0.4: Pattern-based sleep type auto classification
///
/// Determines nap vs night sleep based on the baby's own sleep pattern.
/// Uses weighted median of longest sleep start times from recent days.
///
/// Design principles:
/// - Zero additional user input required
/// - Baby pattern-first, not fixed time zones
/// - Editable: classification result can be overridden in edit sheet
/// - Silent operation: no UI interruption
///
/// Algorithm:
/// 1. Collect longest sleep per day from recent history (7 days)
/// 2. Extract start hours as "night anchors"
/// 3. Compute weighted median (recent days weigh more)
/// 4. Night range = anchor +/- 2 hours
/// 5. If startTime falls in night range -> 'night', else 'nap'
///
/// Cold start: if < 3 days of data, fallback to 21:00~06:00 fixed range.
class SleepClassifier {
  /// Minimum days of data required for pattern-based classification
  static const int minDaysForPattern = 3;

  /// Number of recent days to analyze
  static const int lookbackDays = 7;

  /// Night range radius in hours (anchor +/- this value)
  static const int nightRangeHours = 2;

  /// Cold start night range: 21:00 ~ 06:00
  static const int coldStartNightBegin = 21;
  static const int coldStartNightEnd = 6;

  /// Classify sleep type based on baby's recent sleep pattern
  ///
  /// [startTime] - when the sleep starts (required)
  /// [endTime] - when the sleep ends (null for "sleep now" mode)
  /// [recentSleepRecords] - completed sleep records from recent days
  ///   (should contain at least [lookbackDays] worth of data)
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

    // Extract night anchor from pattern
    final anchor = _extractNightAnchor(completedSleeps, currentTime);

    if (anchor == null) {
      // Cold start: use fixed range
      return _classifyColdStart(startTime);
    }

    // Pattern-based classification
    return _classifyWithAnchor(startTime, anchor);
  }

  /// Extract night anchor hour from recent sleep history
  ///
  /// Finds the longest sleep per day, takes their start hours,
  /// and computes a weighted median (recent days weigh more).
  ///
  /// Returns null if insufficient data (< [minDaysForPattern] days).
  static double? _extractNightAnchor(
    List<ActivityModel> completedSleeps,
    DateTime now,
  ) {
    final cutoff = now.subtract(Duration(days: lookbackDays));

    // Group sleeps by local date
    final Map<String, List<ActivityModel>> sleepsByDate = {};
    for (final sleep in completedSleeps) {
      final localStart = sleep.startTime.toLocal();
      if (localStart.isBefore(cutoff)) continue;

      final dateKey =
          '${localStart.year}-${localStart.month}-${localStart.day}';
      sleepsByDate.putIfAbsent(dateKey, () => []);
      sleepsByDate[dateKey]!.add(sleep);
    }

    if (sleepsByDate.length < minDaysForPattern) {
      return null;
    }

    // Find longest sleep per day -> extract start hour
    final List<_WeightedHour> anchors = [];
    final sortedDates = sleepsByDate.keys.toList()..sort();

    for (int i = 0; i < sortedDates.length; i++) {
      final daySleeps = sleepsByDate[sortedDates[i]]!;

      // Find longest sleep of the day
      ActivityModel? longest;
      int maxDuration = 0;
      for (final sleep in daySleeps) {
        final duration = sleep.endTime!.difference(sleep.startTime).inMinutes;
        if (duration > maxDuration) {
          maxDuration = duration;
          longest = sleep;
        }
      }

      if (longest != null && maxDuration >= 60) {
        // Only consider sleeps >= 1 hour as potential night sleep
        final startHour = longest.startTime.toLocal().hour +
            longest.startTime.toLocal().minute / 60.0;
        // Weight: more recent days get higher weight
        // Day 0 (oldest) = weight 1, most recent = weight N
        final weight = (i + 1).toDouble();
        anchors.add(_WeightedHour(hour: startHour, weight: weight));
      }
    }

    if (anchors.length < minDaysForPattern) {
      return null;
    }

    return _weightedMedian(anchors);
  }

  /// Compute weighted median of hours
  ///
  /// Handles circular hours (23:00 and 01:00 should be close).
  /// Normalizes hours to -12..+12 range relative to midnight before median.
  static double _weightedMedian(List<_WeightedHour> items) {
    if (items.isEmpty) return 21.0;

    // Normalize hours relative to midnight for circular handling
    // Convert to range: -6..+18 (so 21:00 = -3, 23:00 = -1, 01:00 = +1)
    final normalized = items.map((item) {
      final h = item.hour > 12 ? item.hour - 24 : item.hour;
      return _WeightedHour(hour: h, weight: item.weight);
    }).toList();

    // Sort by normalized hour
    normalized.sort((a, b) => a.hour.compareTo(b.hour));

    // Find weighted median
    final totalWeight =
        normalized.fold<double>(0, (sum, item) => sum + item.weight);
    final halfWeight = totalWeight / 2;

    double cumulative = 0;
    for (final item in normalized) {
      cumulative += item.weight;
      if (cumulative >= halfWeight) {
        // Convert back to 0..24 range
        final result = item.hour < 0 ? item.hour + 24 : item.hour;
        return result;
      }
    }

    // Fallback (shouldn't reach here)
    final lastHour = normalized.last.hour;
    return lastHour < 0 ? lastHour + 24 : lastHour;
  }

  /// Classify using pattern-derived night anchor
  ///
  /// Night range: [anchor - nightRangeHours, anchor + nightRangeHours]
  /// with circular wrapping at 24h boundary.
  static String _classifyWithAnchor(DateTime startTime, double anchor) {
    final localHour =
        startTime.toLocal().hour + startTime.toLocal().minute / 60.0;

    final rangeStart = anchor - nightRangeHours;
    final rangeEnd = anchor + nightRangeHours;

    if (_isHourInRange(localHour, rangeStart, rangeEnd)) {
      return 'night';
    }
    return 'nap';
  }

  /// Check if hour falls within circular range
  static bool _isHourInRange(double hour, double rangeStart, double rangeEnd) {
    // Normalize to 0..24
    final normalizedHour = _normalizeHour(hour);
    final normalizedStart = _normalizeHour(rangeStart);
    final normalizedEnd = _normalizeHour(rangeEnd);

    if (normalizedStart <= normalizedEnd) {
      // Normal range (e.g., 19:00 ~ 23:00)
      return normalizedHour >= normalizedStart &&
          normalizedHour <= normalizedEnd;
    } else {
      // Wrapping range (e.g., 23:00 ~ 03:00)
      return normalizedHour >= normalizedStart ||
          normalizedHour <= normalizedEnd;
    }
  }

  /// Normalize hour to 0..24 range
  static double _normalizeHour(double hour) {
    double result = hour % 24;
    if (result < 0) result += 24;
    return result;
  }

  /// Cold start classification: fixed range 21:00 ~ 06:00
  static String _classifyColdStart(DateTime startTime) {
    final hour = startTime.toLocal().hour;
    if (hour >= coldStartNightBegin || hour < coldStartNightEnd) {
      return 'night';
    }
    return 'nap';
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

    final anchor = _extractNightAnchor(completedSleeps, now);
    return anchor == null;
  }

  /// Get the current night anchor hour for debugging/display
  ///
  /// Returns null if in cold start mode.
  static double? getNightAnchor(List<ActivityModel> recentSleepRecords) {
    final now = DateTime.now();

    final completedSleeps = recentSleepRecords.where((a) {
      if (a.type != ActivityType.sleep) return false;
      if (a.endTime == null) return false;
      return a.endTime!.difference(a.startTime).inMinutes > 0;
    }).toList();

    return _extractNightAnchor(completedSleeps, now);
  }
}

/// Internal: hour with weight for weighted median calculation
class _WeightedHour {
  final double hour;
  final double weight;

  const _WeightedHour({required this.hour, required this.weight});
}
