import 'package:flutter_test/flutter_test.dart';
import 'package:lulu_mvp_f/data/models/activity_model.dart';
import 'package:lulu_mvp_f/data/models/baby_type.dart';
import 'package:lulu_mvp_f/data/models/badge_model.dart';
import 'package:lulu_mvp_f/features/badge/badge_engine.dart';

void main() {
  const familyId = 'test-family';
  const babyId = 'test-baby-1';
  const babyId2 = 'test-baby-2';

  // Helper: create feeding activity
  ActivityModel _feeding({
    String id = 'f1',
    String baby = babyId,
    double? amountMl,
    String feedingType = 'bottle',
    DateTime? startTime,
  }) {
    return createFeedingActivity(
      id: id,
      familyId: familyId,
      babyIds: [baby],
      startTime: startTime ?? DateTime(2026, 2, 10, 10, 0),
      amountMl: amountMl,
      feedingType: feedingType,
    );
  }

  // Helper: create sleep activity
  ActivityModel _sleep({
    String id = 's1',
    String baby = babyId,
    DateTime? startTime,
    DateTime? endTime,
    String sleepType = 'nap',
  }) {
    return ActivityModel(
      id: id,
      familyId: familyId,
      babyIds: [baby],
      type: ActivityType.sleep,
      startTime: startTime ?? DateTime(2026, 2, 10, 13, 0),
      endTime: endTime,
      data: {'sleep_type': sleepType},
      createdAt: DateTime.now(),
    );
  }

  // Helper: create diaper activity
  ActivityModel _diaper({
    String id = 'd1',
    String baby = babyId,
    DateTime? startTime,
  }) {
    return createDiaperActivity(
      id: id,
      familyId: familyId,
      babyIds: [baby],
      time: startTime ?? DateTime(2026, 2, 10, 12, 0),
      diaperType: 'wet',
    );
  }

  group('BadgeEngine - Badge Definitions', () {
    test('#1 allBadges has 13 definitions', () {
      expect(BadgeEngine.allBadges.length, 13);
    });

    test('#2 getDefinition returns correct badge', () {
      final def = BadgeEngine.getDefinition('first_feeding');
      expect(def, isNotNull);
      expect(def!.key, 'first_feeding');
      expect(def.category, BadgeCategory.feeding);
      expect(def.tier, BadgeTier.warm);
    });

    test('#3 getDefinition returns null for unknown key', () {
      expect(BadgeEngine.getDefinition('nonexistent'), isNull);
    });

    test('#4 all badge keys are unique', () {
      final keys = BadgeEngine.allBadges.map((b) => b.key).toSet();
      expect(keys.length, BadgeEngine.allBadges.length);
    });
  });

  group('BadgeEngine - Feeding Badges', () {
    test('#5 first_feeding: triggers on first feeding', () {
      final activity = _feeding();
      final candidates = BadgeEngine.check(
        activity: activity,
        allActivities: [activity],
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'first_feeding'),
        isTrue,
      );
    });

    test('#6 first_feeding: skipped if already unlocked', () {
      final activity = _feeding();
      final candidates = BadgeEngine.check(
        activity: activity,
        allActivities: [activity],
        existingBadgeKeys: {'first_feeding:$babyId'},
      );

      expect(
        candidates.any((c) => c.definition.key == 'first_feeding'),
        isFalse,
      );
    });

    test('#7 feeding_10: triggers at exactly 10 feedings', () {
      final activities = List.generate(
        10,
        (i) => _feeding(id: 'f$i'),
      );
      final candidates = BadgeEngine.check(
        activity: activities.last,
        allActivities: activities,
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'feeding_10'),
        isTrue,
      );
    });

    test('#8 feeding_10: does not trigger at 9 feedings', () {
      final activities = List.generate(
        9,
        (i) => _feeding(id: 'f$i'),
      );
      final candidates = BadgeEngine.check(
        activity: activities.last,
        allActivities: activities,
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'feeding_10'),
        isFalse,
      );
    });

    test('#9 feeding_50: triggers at exactly 50 feedings', () {
      final activities = List.generate(
        50,
        (i) => _feeding(id: 'f$i'),
      );
      final candidates = BadgeEngine.check(
        activity: activities.last,
        allActivities: activities,
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'feeding_50'),
        isTrue,
      );
    });

    test('#10 milk_1L: triggers at cumulative 1000ml', () {
      final activities = List.generate(
        10,
        (i) => _feeding(id: 'f$i', amountMl: 100),
      );
      final candidates = BadgeEngine.check(
        activity: activities.last,
        allActivities: activities,
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'milk_1L'),
        isTrue,
      );
    });

    test('#11 milk_1L: excludes solid food', () {
      final activities = [
        ...List.generate(
          9,
          (i) => _feeding(id: 'f$i', amountMl: 100),
        ),
        // This solid food amount should not count
        _feeding(id: 'f9', amountMl: 200, feedingType: 'solid'),
      ];
      final candidates = BadgeEngine.check(
        activity: activities.last,
        allActivities: activities,
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'milk_1L'),
        isFalse,
      );
    });

    test('#12 night_feeding: triggers between midnight and 5AM', () {
      final activity = _feeding(
        startTime: DateTime(2026, 2, 10, 2, 30), // 2:30 AM
      );
      final candidates = BadgeEngine.check(
        activity: activity,
        allActivities: [activity],
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'night_feeding'),
        isTrue,
      );
    });

    test('#13 night_feeding: does not trigger at 5AM or later', () {
      final activity = _feeding(
        startTime: DateTime(2026, 2, 10, 5, 0), // 5:00 AM
      );
      final candidates = BadgeEngine.check(
        activity: activity,
        allActivities: [activity],
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'night_feeding'),
        isFalse,
      );
    });

    test('#14 night_feeding: is family-level (no babyId)', () {
      final activity = _feeding(
        startTime: DateTime(2026, 2, 10, 3, 0),
      );
      final candidates = BadgeEngine.check(
        activity: activity,
        allActivities: [activity],
        existingBadgeKeys: {},
      );

      final nightFeeding = candidates.firstWhere(
        (c) => c.definition.key == 'night_feeding',
      );
      expect(nightFeeding.babyId, isNull);
    });
  });

  group('BadgeEngine - Sleep Badges', () {
    test('#15 first_sleep: triggers on first completed sleep', () {
      final activity = _sleep(
        endTime: DateTime(2026, 2, 10, 14, 0),
      );
      final candidates = BadgeEngine.check(
        activity: activity,
        allActivities: [activity],
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'first_sleep'),
        isTrue,
      );
    });

    test('#16 first_sleep: does NOT trigger for ongoing sleep (no endTime)', () {
      final activity = _sleep(); // no endTime
      final candidates = BadgeEngine.check(
        activity: activity,
        allActivities: [activity],
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'first_sleep'),
        isFalse,
      );
    });

    test('#17 sleep_10: triggers at 10 completed sleeps', () {
      final activities = List.generate(
        10,
        (i) => _sleep(
          id: 's$i',
          endTime: DateTime(2026, 2, 10, 14, 0),
        ),
      );
      final candidates = BadgeEngine.check(
        activity: activities.last,
        allActivities: activities,
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'sleep_10'),
        isTrue,
      );
    });

    test('#18 first_sleep_through: night sleep 7h+ triggers', () {
      final activity = _sleep(
        sleepType: 'night',
        startTime: DateTime(2026, 2, 9, 21, 0), // 9 PM
        endTime: DateTime(2026, 2, 10, 5, 0), // 5 AM = 8 hours
      );
      final candidates = BadgeEngine.check(
        activity: activity,
        allActivities: [activity],
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'first_sleep_through'),
        isTrue,
      );
    });

    test('#19 first_sleep_through: nap does NOT trigger', () {
      final activity = _sleep(
        sleepType: 'nap',
        startTime: DateTime(2026, 2, 10, 10, 0),
        endTime: DateTime(2026, 2, 10, 18, 0), // 8 hours but nap
      );
      final candidates = BadgeEngine.check(
        activity: activity,
        allActivities: [activity],
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'first_sleep_through'),
        isFalse,
      );
    });

    test('#20 first_sleep_through: night sleep under 7h does NOT trigger', () {
      final activity = _sleep(
        sleepType: 'night',
        startTime: DateTime(2026, 2, 9, 23, 0),
        endTime: DateTime(2026, 2, 10, 5, 0), // 6 hours
      );
      final candidates = BadgeEngine.check(
        activity: activity,
        allActivities: [activity],
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'first_sleep_through'),
        isFalse,
      );
    });

    test('#21 sleep_routine_3d: 3 consecutive days with sleep', () {
      final activities = [
        _sleep(id: 's1', startTime: DateTime(2026, 2, 8, 13, 0), endTime: DateTime(2026, 2, 8, 14, 0)),
        _sleep(id: 's2', startTime: DateTime(2026, 2, 9, 13, 0), endTime: DateTime(2026, 2, 9, 14, 0)),
        _sleep(id: 's3', startTime: DateTime(2026, 2, 10, 13, 0), endTime: DateTime(2026, 2, 10, 14, 0)),
      ];
      final candidates = BadgeEngine.check(
        activity: activities.last,
        allActivities: activities,
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'sleep_routine_3d'),
        isTrue,
      );
    });

    test('#22 sleep_routine_3d: non-consecutive days do NOT trigger', () {
      final activities = [
        _sleep(id: 's1', startTime: DateTime(2026, 2, 8, 13, 0), endTime: DateTime(2026, 2, 8, 14, 0)),
        // Gap: Feb 9 missing
        _sleep(id: 's2', startTime: DateTime(2026, 2, 10, 13, 0), endTime: DateTime(2026, 2, 10, 14, 0)),
        _sleep(id: 's3', startTime: DateTime(2026, 2, 11, 13, 0), endTime: DateTime(2026, 2, 11, 14, 0)),
      ];
      final candidates = BadgeEngine.check(
        activity: activities.last,
        allActivities: activities,
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'sleep_routine_3d'),
        isFalse,
      );
    });
  });

  group('BadgeEngine - Parenting Badges', () {
    test('#23 first_record: triggers on any first activity', () {
      final activity = _diaper();
      final candidates = BadgeEngine.check(
        activity: activity,
        allActivities: [activity],
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'first_record'),
        isTrue,
      );
    });

    test('#24 first_record: is family-level (no babyId)', () {
      final activity = _diaper();
      final candidates = BadgeEngine.check(
        activity: activity,
        allActivities: [activity],
        existingBadgeKeys: {},
      );

      final firstRecord = candidates.firstWhere(
        (c) => c.definition.key == 'first_record',
      );
      expect(firstRecord.babyId, isNull);
    });

    test('#25 streak_3d: 3 consecutive recording days', () {
      final activities = [
        _diaper(id: 'd1', startTime: DateTime(2026, 2, 8, 10, 0)),
        _diaper(id: 'd2', startTime: DateTime(2026, 2, 9, 10, 0)),
        _diaper(id: 'd3', startTime: DateTime(2026, 2, 10, 10, 0)),
      ];
      final candidates = BadgeEngine.check(
        activity: activities.last,
        allActivities: activities,
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'streak_3d'),
        isTrue,
      );
    });

    test('#26 streak_7d: 7 consecutive recording days', () {
      final activities = List.generate(
        7,
        (i) => _diaper(
          id: 'd$i',
          startTime: DateTime(2026, 2, 4 + i, 10, 0),
        ),
      );
      final candidates = BadgeEngine.check(
        activity: activities.last,
        allActivities: activities,
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'streak_7d'),
        isTrue,
      );
    });
  });

  group('BadgeEngine - Per-baby isolation', () {
    test('#27 first_feeding for baby1 does not affect baby2', () {
      final baby1Activity = _feeding(baby: babyId);
      final candidates = BadgeEngine.check(
        activity: baby1Activity,
        allActivities: [baby1Activity],
        existingBadgeKeys: {'first_feeding:$babyId2'}, // baby2 already has it
      );

      // Should still trigger for baby1
      expect(
        candidates.any((c) =>
            c.definition.key == 'first_feeding' && c.babyId == babyId),
        isTrue,
      );
    });

    test('#28 existing badge key prevents duplicate', () {
      final activity = _feeding();
      final candidates = BadgeEngine.check(
        activity: activity,
        allActivities: [activity],
        existingBadgeKeys: {'first_feeding:$babyId'},
      );

      expect(
        candidates.any((c) => c.definition.key == 'first_feeding'),
        isFalse,
      );
    });
  });

  group('BadgeEngine - Sleep day boundary (4 AM)', () {
    test('#29 activity at 3AM belongs to previous day', () {
      // 3 activities at 3AM on Feb 9, 10, 11 → should count as Feb 8, 9, 10
      final activities = [
        _sleep(id: 's1', startTime: DateTime(2026, 2, 9, 3, 0), endTime: DateTime(2026, 2, 9, 4, 0)),
        _sleep(id: 's2', startTime: DateTime(2026, 2, 10, 3, 0), endTime: DateTime(2026, 2, 10, 4, 0)),
        _sleep(id: 's3', startTime: DateTime(2026, 2, 11, 3, 0), endTime: DateTime(2026, 2, 11, 4, 0)),
      ];
      final candidates = BadgeEngine.check(
        activity: activities.last,
        allActivities: activities,
        existingBadgeKeys: {},
      );

      expect(
        candidates.any((c) => c.definition.key == 'sleep_routine_3d'),
        isTrue,
      );
    });
  });

  group('BadgeEngine - Bulk check', () {
    test('#30 checkBulk finds all applicable badges', () {
      final activities = List.generate(
        10,
        (i) => _feeding(id: 'f$i', amountMl: 100),
      );
      final candidates = BadgeEngine.checkBulk(
        allActivities: activities,
        existingBadgeKeys: {},
      );

      // Should find: first_record, first_feeding, feeding_10, milk_1L
      expect(candidates.length, greaterThanOrEqualTo(3));
      expect(candidates.any((c) => c.definition.key == 'first_record'), isTrue);
      expect(candidates.any((c) => c.definition.key == 'first_feeding'), isTrue);
      expect(candidates.any((c) => c.definition.key == 'feeding_10'), isTrue);
    });

    test('#31 checkBulk deduplicates results', () {
      final activities = List.generate(
        5,
        (i) => _feeding(id: 'f$i'),
      );
      final candidates = BadgeEngine.checkBulk(
        allActivities: activities,
        existingBadgeKeys: {},
      );

      // first_feeding should appear only once per baby
      final firstFeedingCount = candidates
          .where((c) => c.definition.key == 'first_feeding' && c.babyId == babyId)
          .length;
      expect(firstFeedingCount, 1);
    });

    test('#32 checkBulk respects existing badge keys', () {
      final activities = [_feeding()];
      final candidates = BadgeEngine.checkBulk(
        allActivities: activities,
        existingBadgeKeys: {'first_feeding:$babyId', 'first_record'},
      );

      expect(candidates.any((c) => c.definition.key == 'first_feeding'), isFalse);
      expect(candidates.any((c) => c.definition.key == 'first_record'), isFalse);
    });
  });

  group('BadgeEngine - buildExistingKeys', () {
    test('#33 builds correct composite keys', () {
      final achievements = [
        BadgeAchievement(
          id: '1',
          familyId: familyId,
          babyId: babyId,
          badgeKey: 'first_feeding',
          tier: BadgeTier.warm,
          unlockedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
        BadgeAchievement(
          id: '2',
          familyId: familyId,
          babyId: null,
          badgeKey: 'first_record',
          tier: BadgeTier.warm,
          unlockedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ];

      final keys = BadgeEngine.buildExistingKeys(achievements);
      expect(keys.contains('first_feeding:$babyId'), isTrue);
      expect(keys.contains('first_record'), isTrue);
    });
  });

  group('BadgeEngine - Multiple badges at once', () {
    test('#34 first activity triggers both first_record and first_feeding', () {
      final activity = _feeding();
      final candidates = BadgeEngine.check(
        activity: activity,
        allActivities: [activity],
        existingBadgeKeys: {},
      );

      expect(candidates.any((c) => c.definition.key == 'first_record'), isTrue);
      expect(candidates.any((c) => c.definition.key == 'first_feeding'), isTrue);
    });

    test('#35 night feeding triggers both first_record and night_feeding', () {
      final activity = _feeding(
        startTime: DateTime(2026, 2, 10, 2, 0), // 2 AM
      );
      final candidates = BadgeEngine.check(
        activity: activity,
        allActivities: [activity],
        existingBadgeKeys: {},
      );

      expect(candidates.any((c) => c.definition.key == 'first_record'), isTrue);
      expect(candidates.any((c) => c.definition.key == 'night_feeding'), isTrue);
      expect(candidates.any((c) => c.definition.key == 'first_feeding'), isTrue);
    });
  });
}
