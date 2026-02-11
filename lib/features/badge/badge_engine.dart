import '../../data/models/activity_model.dart';
import '../../data/models/baby_type.dart';
import '../../data/models/badge_model.dart';
import '../../data/models/feeding_type.dart';

/// Badge Engine — pure logic, no side effects.
///
/// Checks whether a newly saved activity triggers any badge unlock.
/// All 13 badge definitions are declared here.
///
/// Design decisions (Deep Dive #1-#5):
/// - wakeUpCount unavailable → sleep_through = night + 7h+
/// - SleepType is String in data map → data['sleep_type'] == 'night'
/// - feedingContentType enum for solid exclusion
/// - babyIds is List of String → filter by contains
/// - Historical data passed in (provider loads from Supabase, cached)
class BadgeEngine {
  const BadgeEngine._();

  // ============================================================
  // 13 Badge Definitions (static registry)
  // ============================================================

  static const List<BadgeDefinition> allBadges = [
    // --- Feeding (5) ---
    BadgeDefinition(
      key: 'first_feeding',
      titleKey: 'badgeFirstFeedingTitle',
      descriptionKey: 'badgeFirstFeedingDesc',
      category: BadgeCategory.feeding,
      tier: BadgeTier.warm,
      perBaby: true,
      sortOrder: 1,
    ),
    BadgeDefinition(
      key: 'feeding_10',
      titleKey: 'badgeFeeding10Title',
      descriptionKey: 'badgeFeeding10Desc',
      category: BadgeCategory.feeding,
      tier: BadgeTier.normal,
      perBaby: true,
      sortOrder: 2,
    ),
    BadgeDefinition(
      key: 'feeding_50',
      titleKey: 'badgeFeeding50Title',
      descriptionKey: 'badgeFeeding50Desc',
      category: BadgeCategory.feeding,
      tier: BadgeTier.warm,
      perBaby: true,
      sortOrder: 3,
    ),
    BadgeDefinition(
      key: 'milk_1L',
      titleKey: 'badgeMilk1LTitle',
      descriptionKey: 'badgeMilk1LDesc',
      category: BadgeCategory.feeding,
      tier: BadgeTier.warm,
      perBaby: true,
      sortOrder: 4,
    ),
    BadgeDefinition(
      key: 'night_feeding',
      titleKey: 'badgeNightFeedingTitle',
      descriptionKey: 'badgeNightFeedingDesc',
      category: BadgeCategory.feeding,
      tier: BadgeTier.tearful,
      perBaby: false,
      sortOrder: 5,
    ),

    // --- Sleep (5) ---
    BadgeDefinition(
      key: 'first_sleep',
      titleKey: 'badgeFirstSleepTitle',
      descriptionKey: 'badgeFirstSleepDesc',
      category: BadgeCategory.sleep,
      tier: BadgeTier.warm,
      perBaby: true,
      sortOrder: 6,
    ),
    BadgeDefinition(
      key: 'sleep_10',
      titleKey: 'badgeSleep10Title',
      descriptionKey: 'badgeSleep10Desc',
      category: BadgeCategory.sleep,
      tier: BadgeTier.normal,
      perBaby: true,
      sortOrder: 7,
    ),
    BadgeDefinition(
      key: 'first_sleep_through',
      titleKey: 'badgeSleepThroughTitle',
      descriptionKey: 'badgeSleepThroughDesc',
      category: BadgeCategory.sleep,
      tier: BadgeTier.tearful,
      perBaby: true,
      sortOrder: 8,
    ),
    BadgeDefinition(
      key: 'sleep_routine_3d',
      titleKey: 'badgeSleepRoutineTitle',
      descriptionKey: 'badgeSleepRoutineDesc',
      category: BadgeCategory.sleep,
      tier: BadgeTier.normal,
      perBaby: true,
      sortOrder: 9,
    ),
    BadgeDefinition(
      key: 'sleep_routine_7d',
      titleKey: 'badgeSleepWeekTitle',
      descriptionKey: 'badgeSleepWeekDesc',
      category: BadgeCategory.sleep,
      tier: BadgeTier.warm,
      perBaby: true,
      sortOrder: 10,
    ),

    // --- Parenting (3) ---
    BadgeDefinition(
      key: 'first_record',
      titleKey: 'badgeFirstRecordTitle',
      descriptionKey: 'badgeFirstRecordDesc',
      category: BadgeCategory.parenting,
      tier: BadgeTier.warm,
      perBaby: false,
      sortOrder: 11,
    ),
    BadgeDefinition(
      key: 'streak_3d',
      titleKey: 'badge3DayStreakTitle',
      descriptionKey: 'badge3DayStreakDesc',
      category: BadgeCategory.parenting,
      tier: BadgeTier.normal,
      perBaby: false,
      sortOrder: 12,
    ),
    BadgeDefinition(
      key: 'streak_7d',
      titleKey: 'badge7DayStreakTitle',
      descriptionKey: 'badge7DayStreakDesc',
      category: BadgeCategory.parenting,
      tier: BadgeTier.warm,
      perBaby: false,
      sortOrder: 13,
    ),
  ];

  /// Lookup badge definition by key
  static BadgeDefinition? getDefinition(String key) {
    try {
      return allBadges.firstWhere((b) => b.key == key);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // Single activity check (called after each save)
  // ============================================================

  /// Check which badges are newly unlocked by [activity].
  ///
  /// [allActivities]: all historical activities for this family (cached).
  /// [existingBadgeKeys]: set of already-unlocked badge keys.
  /// Returns list of (BadgeDefinition, babyId?) pairs to unlock.
  static List<BadgeUnlockCandidate> check({
    required ActivityModel activity,
    required List<ActivityModel> allActivities,
    required Set<String> existingBadgeKeys,
  }) {
    final List<BadgeUnlockCandidate> candidates = [];

    // Per-baby badges
    for (final babyId in activity.babyIds) {
      final babyActivities = allActivities
          .where((a) => a.babyIds.contains(babyId))
          .toList();

      // Feeding badges (per-baby)
      if (activity.type == ActivityType.feeding) {
        final feedingActivities = babyActivities
            .where((a) => a.type == ActivityType.feeding)
            .toList();

        _checkFirstFeeding(
          feedingActivities, babyId, existingBadgeKeys, candidates,
        );
        _checkFeeding10(
          feedingActivities, babyId, existingBadgeKeys, candidates,
        );
        _checkFeeding50(
          feedingActivities, babyId, existingBadgeKeys, candidates,
        );
        _checkMilk1L(
          feedingActivities, babyId, existingBadgeKeys, candidates,
        );
      }

      // Sleep badges (per-baby)
      if (activity.type == ActivityType.sleep) {
        final sleepActivities = babyActivities
            .where((a) => a.type == ActivityType.sleep)
            .toList();
        final completedSleepActivities = sleepActivities
            .where((a) => a.endTime != null)
            .toList();

        _checkFirstSleep(
          completedSleepActivities, babyId, existingBadgeKeys, candidates,
        );
        _checkSleep10(
          completedSleepActivities, babyId, existingBadgeKeys, candidates,
        );
        _checkSleepThrough(
          activity, babyId, existingBadgeKeys, candidates,
        );
        _checkSleepRoutine3d(
          completedSleepActivities, babyId, existingBadgeKeys, candidates,
        );
        _checkSleepRoutine7d(
          completedSleepActivities, babyId, existingBadgeKeys, candidates,
        );
      }
    }

    // Family-level badges (not per-baby)
    _checkFirstRecord(allActivities, existingBadgeKeys, candidates);
    _checkNightFeeding(activity, existingBadgeKeys, candidates);
    _checkStreak3d(allActivities, existingBadgeKeys, candidates);
    _checkStreak7d(allActivities, existingBadgeKeys, candidates);

    return candidates;
  }

  // ============================================================
  // Bulk check (for import — Phase 7.5)
  // ============================================================

  /// Check all badges after bulk import.
  ///
  /// Iterates through all activities and collects all unlockable badges.
  /// Does NOT trigger popups (silent unlock).
  static List<BadgeUnlockCandidate> checkBulk({
    required List<ActivityModel> allActivities,
    required Set<String> existingBadgeKeys,
  }) {
    final List<BadgeUnlockCandidate> candidates = [];
    // Track keys found during this bulk check to avoid duplicates
    final Set<String> foundKeys = {};

    // Collect all unique baby IDs
    final Set<String> allBabyIds = {};
    for (final a in allActivities) {
      allBabyIds.addAll(a.babyIds);
    }

    // Per-baby badges
    for (final babyId in allBabyIds) {
      final babyActivities = allActivities
          .where((a) => a.babyIds.contains(babyId))
          .toList();

      final feedingActivities = babyActivities
          .where((a) => a.type == ActivityType.feeding)
          .toList();
      final completedSleepActivities = babyActivities
          .where((a) => a.type == ActivityType.sleep && a.endTime != null)
          .toList();

      // Feeding
      _checkFirstFeeding(feedingActivities, babyId, existingBadgeKeys, candidates);
      _checkFeeding10(feedingActivities, babyId, existingBadgeKeys, candidates);
      _checkFeeding50(feedingActivities, babyId, existingBadgeKeys, candidates);
      _checkMilk1L(feedingActivities, babyId, existingBadgeKeys, candidates);

      // Sleep
      _checkFirstSleep(completedSleepActivities, babyId, existingBadgeKeys, candidates);
      _checkSleep10(completedSleepActivities, babyId, existingBadgeKeys, candidates);
      _checkSleepRoutine3d(completedSleepActivities, babyId, existingBadgeKeys, candidates);
      _checkSleepRoutine7d(completedSleepActivities, babyId, existingBadgeKeys, candidates);

      // Sleep through — check each completed night sleep
      for (final sleepActivity in completedSleepActivities) {
        final key = _badgeKeyWithBaby('first_sleep_through', babyId);
        if (!existingBadgeKeys.contains(key) && !foundKeys.contains(key)) {
          _checkSleepThrough(sleepActivity, babyId, existingBadgeKeys, candidates);
          if (candidates.any((c) => c.definition.key == 'first_sleep_through' && c.babyId == babyId)) {
            foundKeys.add(key);
          }
        }
      }
    }

    // Family-level badges
    _checkFirstRecord(allActivities, existingBadgeKeys, candidates);
    _checkStreak3d(allActivities, existingBadgeKeys, candidates);
    _checkStreak7d(allActivities, existingBadgeKeys, candidates);

    // Night feeding — check each feeding
    for (final activity in allActivities) {
      if (activity.type == ActivityType.feeding) {
        const key = 'night_feeding';
        if (!existingBadgeKeys.contains(key) && !foundKeys.contains(key)) {
          _checkNightFeeding(activity, existingBadgeKeys, candidates);
          if (candidates.any((c) => c.definition.key == key)) {
            foundKeys.add(key);
          }
        }
      }
    }

    // Deduplicate candidates
    final Map<String, BadgeUnlockCandidate> unique = {};
    for (final c in candidates) {
      final dedupKey = _badgeKeyWithBaby(c.definition.key, c.babyId);
      unique.putIfAbsent(dedupKey, () => c);
    }

    return unique.values.toList();
  }

  // ============================================================
  // Feeding conditions
  // ============================================================

  static void _checkFirstFeeding(
    List<ActivityModel> feedingActivities,
    String babyId,
    Set<String> existingKeys,
    List<BadgeUnlockCandidate> candidates,
  ) {
    final key = _badgeKeyWithBaby('first_feeding', babyId);
    if (existingKeys.contains(key)) return;
    if (feedingActivities.isNotEmpty) {
      candidates.add(BadgeUnlockCandidate(
        definition: allBadges.firstWhere((b) => b.key == 'first_feeding'),
        babyId: babyId,
      ));
    }
  }

  static void _checkFeeding10(
    List<ActivityModel> feedingActivities,
    String babyId,
    Set<String> existingKeys,
    List<BadgeUnlockCandidate> candidates,
  ) {
    final key = _badgeKeyWithBaby('feeding_10', babyId);
    if (existingKeys.contains(key)) return;
    if (feedingActivities.length >= 10) {
      candidates.add(BadgeUnlockCandidate(
        definition: allBadges.firstWhere((b) => b.key == 'feeding_10'),
        babyId: babyId,
      ));
    }
  }

  static void _checkFeeding50(
    List<ActivityModel> feedingActivities,
    String babyId,
    Set<String> existingKeys,
    List<BadgeUnlockCandidate> candidates,
  ) {
    final key = _badgeKeyWithBaby('feeding_50', babyId);
    if (existingKeys.contains(key)) return;
    if (feedingActivities.length >= 50) {
      candidates.add(BadgeUnlockCandidate(
        definition: allBadges.firstWhere((b) => b.key == 'feeding_50'),
        babyId: babyId,
      ));
    }
  }

  /// Cumulative milk >= 1000ml (excluding solid food)
  static void _checkMilk1L(
    List<ActivityModel> feedingActivities,
    String babyId,
    Set<String> existingKeys,
    List<BadgeUnlockCandidate> candidates,
  ) {
    final key = _badgeKeyWithBaby('milk_1L', babyId);
    if (existingKeys.contains(key)) return;

    double totalMl = 0;
    for (final a in feedingActivities) {
      // Exclude solid food (Deep Dive #3)
      if (a.feedingContentType == FeedingContentType.solid) continue;
      final amount = a.feedingAmountMl;
      if (amount != null && amount > 0) {
        totalMl += amount;
      }
    }

    if (totalMl >= 1000) {
      candidates.add(BadgeUnlockCandidate(
        definition: allBadges.firstWhere((b) => b.key == 'milk_1L'),
        babyId: babyId,
      ));
    }
  }

  /// Night feeding: midnight (0:00) ~ 5:00 AM
  static void _checkNightFeeding(
    ActivityModel activity,
    Set<String> existingKeys,
    List<BadgeUnlockCandidate> candidates,
  ) {
    const key = 'night_feeding';
    if (existingKeys.contains(key)) return;
    if (activity.type != ActivityType.feeding) return;

    final hour = activity.startTime.toLocal().hour;
    if (hour >= 0 && hour < 5) {
      candidates.add(BadgeUnlockCandidate(
        definition: allBadges.firstWhere((b) => b.key == key),
        babyId: null, // family-level
      ));
    }
  }

  // ============================================================
  // Sleep conditions
  // ============================================================

  static void _checkFirstSleep(
    List<ActivityModel> completedSleepActivities,
    String babyId,
    Set<String> existingKeys,
    List<BadgeUnlockCandidate> candidates,
  ) {
    final key = _badgeKeyWithBaby('first_sleep', babyId);
    if (existingKeys.contains(key)) return;
    if (completedSleepActivities.isNotEmpty) {
      candidates.add(BadgeUnlockCandidate(
        definition: allBadges.firstWhere((b) => b.key == 'first_sleep'),
        babyId: babyId,
      ));
    }
  }

  static void _checkSleep10(
    List<ActivityModel> completedSleepActivities,
    String babyId,
    Set<String> existingKeys,
    List<BadgeUnlockCandidate> candidates,
  ) {
    final key = _badgeKeyWithBaby('sleep_10', babyId);
    if (existingKeys.contains(key)) return;
    if (completedSleepActivities.length >= 10) {
      candidates.add(BadgeUnlockCandidate(
        definition: allBadges.firstWhere((b) => b.key == 'sleep_10'),
        babyId: babyId,
      ));
    }
  }

  /// First sleep through: night sleep + 7h+ (Deep Dive #1)
  /// No wakeUpCount available, so we use duration >= 420 min.
  static void _checkSleepThrough(
    ActivityModel activity,
    String babyId,
    Set<String> existingKeys,
    List<BadgeUnlockCandidate> candidates,
  ) {
    final key = _badgeKeyWithBaby('first_sleep_through', babyId);
    if (existingKeys.contains(key)) return;
    if (activity.type != ActivityType.sleep) return;
    if (activity.endTime == null) return; // must be completed

    // Must be night sleep (Deep Dive #2)
    final sleepType = activity.data?['sleep_type'] as String?;
    if (sleepType != 'night') return;

    // Duration >= 7 hours (420 minutes)
    final duration = activity.durationMinutes;
    if (duration != null && duration >= 420) {
      candidates.add(BadgeUnlockCandidate(
        definition: allBadges.firstWhere((b) => b.key == 'first_sleep_through'),
        babyId: babyId,
      ));
    }
  }

  /// Sleep routine: 3 consecutive days with sleep records
  /// Day boundary: 4:00 AM (sleep medicine convention)
  static void _checkSleepRoutine3d(
    List<ActivityModel> completedSleepActivities,
    String babyId,
    Set<String> existingKeys,
    List<BadgeUnlockCandidate> candidates,
  ) {
    final key = _badgeKeyWithBaby('sleep_routine_3d', babyId);
    if (existingKeys.contains(key)) return;

    if (_hasConsecutiveSleepDays(completedSleepActivities, 3)) {
      candidates.add(BadgeUnlockCandidate(
        definition: allBadges.firstWhere((b) => b.key == 'sleep_routine_3d'),
        babyId: babyId,
      ));
    }
  }

  static void _checkSleepRoutine7d(
    List<ActivityModel> completedSleepActivities,
    String babyId,
    Set<String> existingKeys,
    List<BadgeUnlockCandidate> candidates,
  ) {
    final key = _badgeKeyWithBaby('sleep_routine_7d', babyId);
    if (existingKeys.contains(key)) return;

    if (_hasConsecutiveSleepDays(completedSleepActivities, 7)) {
      candidates.add(BadgeUnlockCandidate(
        definition: allBadges.firstWhere((b) => b.key == 'sleep_routine_7d'),
        babyId: babyId,
      ));
    }
  }

  // ============================================================
  // Parenting conditions (family-level)
  // ============================================================

  static void _checkFirstRecord(
    List<ActivityModel> allActivities,
    Set<String> existingKeys,
    List<BadgeUnlockCandidate> candidates,
  ) {
    const key = 'first_record';
    if (existingKeys.contains(key)) return;
    if (allActivities.isNotEmpty) {
      candidates.add(BadgeUnlockCandidate(
        definition: allBadges.firstWhere((b) => b.key == key),
        babyId: null,
      ));
    }
  }

  /// 3 consecutive days with any record
  static void _checkStreak3d(
    List<ActivityModel> allActivities,
    Set<String> existingKeys,
    List<BadgeUnlockCandidate> candidates,
  ) {
    const key = 'streak_3d';
    if (existingKeys.contains(key)) return;

    if (_hasConsecutiveRecordDays(allActivities, 3)) {
      candidates.add(BadgeUnlockCandidate(
        definition: allBadges.firstWhere((b) => b.key == key),
        babyId: null,
      ));
    }
  }

  /// 7 consecutive days with any record
  static void _checkStreak7d(
    List<ActivityModel> allActivities,
    Set<String> existingKeys,
    List<BadgeUnlockCandidate> candidates,
  ) {
    const key = 'streak_7d';
    if (existingKeys.contains(key)) return;

    if (_hasConsecutiveRecordDays(allActivities, 7)) {
      candidates.add(BadgeUnlockCandidate(
        definition: allBadges.firstWhere((b) => b.key == key),
        babyId: null,
      ));
    }
  }

  // ============================================================
  // Helpers
  // ============================================================

  /// Build composite key for existingBadgeKeys lookup
  ///
  /// Per-baby: "badge_key:baby_id"
  /// Family-level: "badge_key"
  static String _badgeKeyWithBaby(String badgeKey, String? babyId) {
    if (babyId != null) return '$badgeKey:$babyId';
    return badgeKey;
  }

  /// Build the existingBadgeKeys set from achievements list
  static Set<String> buildExistingKeys(List<BadgeAchievement> achievements) {
    return achievements.map((a) => _badgeKeyWithBaby(a.badgeKey, a.babyId)).toSet();
  }

  /// Check N consecutive days with sleep records.
  /// Day boundary: 4:00 AM (sleep medicine convention).
  static bool _hasConsecutiveSleepDays(
    List<ActivityModel> sleepActivities,
    int requiredDays,
  ) {
    if (sleepActivities.length < requiredDays) return false;

    final uniqueDays = _getUniqueSleepDays(sleepActivities);
    return _hasConsecutiveDays(uniqueDays, requiredDays);
  }

  /// Check N consecutive days with any record.
  /// Day boundary: 4:00 AM.
  static bool _hasConsecutiveRecordDays(
    List<ActivityModel> activities,
    int requiredDays,
  ) {
    if (activities.length < requiredDays) return false;

    final uniqueDays = <DateTime>{};
    for (final a in activities) {
      uniqueDays.add(_toSleepDay(a.startTime.toLocal()));
    }
    return _hasConsecutiveDays(uniqueDays, requiredDays);
  }

  /// Convert time to "sleep day" (4 AM boundary).
  /// 0:00-3:59 → previous day, 4:00-23:59 → current day.
  static DateTime _toSleepDay(DateTime localTime) {
    if (localTime.hour < 4) {
      final prev = localTime.subtract(const Duration(days: 1));
      return DateTime(prev.year, prev.month, prev.day);
    }
    return DateTime(localTime.year, localTime.month, localTime.day);
  }

  /// Get unique sleep days from activities
  static Set<DateTime> _getUniqueSleepDays(List<ActivityModel> activities) {
    final Set<DateTime> days = {};
    for (final a in activities) {
      days.add(_toSleepDay(a.startTime.toLocal()));
    }
    return days;
  }

  /// Check if set of days contains N consecutive days
  static bool _hasConsecutiveDays(Set<DateTime> days, int required) {
    if (days.length < required) return false;

    final sorted = days.toList()..sort();
    int streak = 1;

    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        streak++;
        if (streak >= required) return true;
      } else if (diff > 1) {
        streak = 1;
      }
      // diff == 0 means same day, skip
    }

    return streak >= required;
  }
}

/// Result of a badge check — candidate to unlock.
class BadgeUnlockCandidate {
  final BadgeDefinition definition;
  final String? babyId; // null for family-level badges

  const BadgeUnlockCandidate({
    required this.definition,
    this.babyId,
  });

  @override
  String toString() =>
      'BadgeUnlockCandidate(${definition.key}, baby: $babyId)';
}
