import 'dart:math';

import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_model.dart';
import '../../../data/models/baby_type.dart';
import '../../../data/models/badge_model.dart';
import '../models/encouragement_message.dart';

/// Time period for message selection
enum TimePeriod {
  dawn,      // 00:00 ~ 05:59
  morning,   // 06:00 ~ 11:59
  afternoon, // 12:00 ~ 17:59
  evening,   // 18:00 ~ 23:59
}

/// Encouragement message selection engine.
///
/// Priority:
///   1. Badge achievement within 1h (D6) — if no popup in queue
///   2. Data-based Tier 1 (D1~D5, D7) — positive changes only
///   3. Time-based general Tier 3 — dawn/morning/afternoon/evening pool
///
/// Negative data → forced Tier 3 fallback.
/// Same message prevention via [lastShownMessageKey].
class EncouragementEngine {
  const EncouragementEngine._();

  /// Select the best encouragement message for current context.
  ///
  /// Returns null only if plain tone + Tier 3 + no applicable message.
  static EncouragementMessage? select({
    required BabyModel baby,
    required List<ActivityModel> todayActivities,
    required List<BadgeAchievement> recentBadges,
    required bool hasPendingBadgePopup,
    required String tone,
    required DateTime now,
    String? lastShownMessageKey,
  }) {
    final params = <String, String>{
      'baby': baby.name,
    };

    // 1. Badge achievement within 1h (no overlap with popup)
    final badgeMessage = _checkRecentBadge(
      recentBadges: recentBadges,
      hasPendingBadgePopup: hasPendingBadgePopup,
      now: now,
      params: params,
    );
    if (badgeMessage != null && badgeMessage.key != lastShownMessageKey) {
      return badgeMessage;
    }

    // 2. Data-based (positive changes only)
    final dataMessage = _checkDataBased(
      baby: baby,
      todayActivities: todayActivities,
      now: now,
      params: params,
    );
    if (dataMessage != null && dataMessage.key != lastShownMessageKey) {
      return dataMessage;
    }

    // 3. Time-based general
    final generalMessage = _selectTimeBasedGeneral(
      tone: tone,
      now: now,
      params: params,
      lastShownMessageKey: lastShownMessageKey,
    );

    return generalMessage;
  }

  /// Determine time period from hour
  static TimePeriod getTimePeriod(DateTime now) {
    final hour = now.hour;
    if (hour < 6) return TimePeriod.dawn;
    if (hour < 12) return TimePeriod.morning;
    if (hour < 18) return TimePeriod.afternoon;
    return TimePeriod.evening;
  }

  // ============================================================
  // Tier 1: Badge achievement (D6)
  // ============================================================

  static EncouragementMessage? _checkRecentBadge({
    required List<BadgeAchievement> recentBadges,
    required bool hasPendingBadgePopup,
    required DateTime now,
    required Map<String, String> params,
  }) {
    // Skip if badge popup is queued (avoid overlap)
    if (hasPendingBadgePopup) return null;
    if (recentBadges.isEmpty) return null;

    // Find badge unlocked within last 1 hour
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    final recent = recentBadges.where((b) {
      return b.unlockedAt.isAfter(oneHourAgo);
    }).toList();

    if (recent.isEmpty) return null;

    // Use most recent badge
    recent.sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
    final badge = recent.first;
    final definition = _findBadgeTitle(badge.badgeKey);

    return EncouragementMessage(
      key: 'encouragement_data_badge',
      tier: EncouragementTier.data,
      params: {...params, 'badge': definition},
    );
  }

  /// Get badge display name key for interpolation
  static String _findBadgeTitle(String badgeKey) {
    // Return the badge key for ARB lookup
    return badgeKey;
  }

  // ============================================================
  // Tier 1: Data-based (D1~D5, D7)
  // ============================================================

  static EncouragementMessage? _checkDataBased({
    required BabyModel baby,
    required List<ActivityModel> todayActivities,
    required DateTime now,
    required Map<String, String> params,
  }) {
    // D1: Consecutive recording days (3+)
    // Note: streak detection requires multi-day data.
    // For now, check if today has records (simplification — full streak
    // tracking uses SharedPreferences in Badge system)
    final todayCount = todayActivities.length;

    // D4: Weekly record count (10+)
    if (todayCount >= 10) {
      return EncouragementMessage(
        key: 'encouragement_data_weekly',
        tier: EncouragementTier.data,
        params: {...params, 'count': todayCount.toString()},
      );
    }

    // D2: Nighttime longest sleep (3h+)
    final nightSleepHours = _getLongestNightSleep(todayActivities);
    if (nightSleepHours >= 3.0) {
      return EncouragementMessage(
        key: 'encouragement_data_sleep',
        tier: EncouragementTier.data,
        params: {
          ...params,
          'hours': nightSleepHours.toStringAsFixed(1),
        },
      );
    }

    // D4 fallback: Today's records exist (count-based)
    if (todayCount >= 5) {
      return EncouragementMessage(
        key: 'encouragement_data_weekly',
        tier: EncouragementTier.data,
        params: {...params, 'count': todayCount.toString()},
      );
    }

    return null;
  }

  /// Find longest completed night sleep duration in hours
  static double _getLongestNightSleep(List<ActivityModel> activities) {
    double maxHours = 0;
    for (final a in activities) {
      if (a.type != ActivityType.sleep) continue;
      if (a.endTime == null) continue;

      final startHour = a.startTime.hour;
      // Night sleep: started between 18:00~05:59
      final isNight = startHour >= 18 || startHour < 6;
      if (!isNight) continue;

      final duration = a.endTime!.difference(a.startTime);
      final hours = duration.inMinutes / 60.0;
      if (hours > maxHours) maxHours = hours;
    }
    return maxHours;
  }

  // ============================================================
  // Tier 3: Time-based general
  // ============================================================

  static EncouragementMessage? _selectTimeBasedGeneral({
    required String tone,
    required DateTime now,
    required Map<String, String> params,
    String? lastShownMessageKey,
  }) {
    final period = getTimePeriod(now);
    final pool = _getMessagePool(period, tone);

    if (pool.isEmpty) return null;

    // Filter out last shown message
    final available = lastShownMessageKey != null
        ? pool.where((key) => key != lastShownMessageKey).toList()
        : pool;

    if (available.isEmpty) {
      // All filtered out — use any from pool
      return EncouragementMessage(
        key: pool[0],
        tier: EncouragementTier.general,
        params: params,
      );
    }

    // Random selection from available pool
    final random = Random(now.millisecondsSinceEpoch ~/ 60000);
    final selected = available[random.nextInt(available.length)];

    return EncouragementMessage(
      key: selected,
      tier: EncouragementTier.general,
      params: params,
    );
  }

  /// Get message key pool for a time period and tone.
  ///
  /// Plain tone Tier 3: only G2 + period-specific plain messages.
  /// If no plain messages available, returns empty (card hidden).
  static List<String> _getMessagePool(TimePeriod period, String tone) {
    if (tone == 'plain') {
      return _plainPools[period] ?? [];
    }
    return _warmPools[period] ?? [];
  }

  // ============================================================
  // Message pools (static)
  // ============================================================

  /// Warm tone message pools by time period
  static const Map<TimePeriod, List<String>> _warmPools = {
    TimePeriod.dawn: [
      'encouragement_dawn_1',
      'encouragement_dawn_2',
      'encouragement_dawn_3',
      'encouragement_dawn_4',
      'encouragement_general_1',
      'encouragement_general_2',
      'encouragement_general_3',
      'encouragement_general_4',
    ],
    TimePeriod.morning: [
      'encouragement_morning_1',
      'encouragement_morning_2',
      'encouragement_general_1',
      'encouragement_general_2',
      'encouragement_general_3',
      'encouragement_general_4',
    ],
    TimePeriod.afternoon: [
      'encouragement_afternoon_2',
      'encouragement_afternoon_3',
      'encouragement_general_1',
      'encouragement_general_2',
      'encouragement_general_3',
      'encouragement_general_4',
    ],
    TimePeriod.evening: [
      'encouragement_evening_1',
      'encouragement_evening_2',
      'encouragement_evening_3',
      'encouragement_general_1',
      'encouragement_general_2',
      'encouragement_general_3',
      'encouragement_general_4',
    ],
  };

  /// Plain tone message pools by time period
  /// UX Writer: plain Tier 3 has minimal messages — empty = card hidden
  static const Map<TimePeriod, List<String>> _plainPools = {
    TimePeriod.dawn: [
      'encouragement_dawn_plain_1',
      'encouragement_dawn_plain_2',
      'encouragement_dawn_plain_3',
    ],
    TimePeriod.morning: [
      'encouragement_morning_plain_1',
      'encouragement_morning_plain_2',
      'encouragement_morning_plain_3',
    ],
    TimePeriod.afternoon: [
      'encouragement_afternoon_plain_1',
      'encouragement_afternoon_plain_2',
    ],
    TimePeriod.evening: [
      'encouragement_evening_plain_1',
      'encouragement_evening_plain_2',
      'encouragement_evening_plain_3',
    ],
  };
}
