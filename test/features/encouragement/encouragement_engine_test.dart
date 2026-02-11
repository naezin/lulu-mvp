import 'package:flutter_test/flutter_test.dart';
import 'package:lulu_mvp_f/data/models/activity_model.dart';
import 'package:lulu_mvp_f/data/models/baby_model.dart';
import 'package:lulu_mvp_f/data/models/baby_type.dart';
import 'package:lulu_mvp_f/data/models/badge_model.dart';
import 'package:lulu_mvp_f/features/encouragement/engine/encouragement_engine.dart';
import 'package:lulu_mvp_f/features/encouragement/models/encouragement_message.dart';

void main() {
  final testBaby = BabyModel(
    id: 'baby-1',
    familyId: 'family-1',
    name: 'TestBaby',
    birthDate: DateTime(2026, 1, 1),
    gender: Gender.unknown,
    createdAt: DateTime(2026, 1, 1),
  );

  BadgeAchievement _makeBadge({
    required String key,
    required DateTime unlockedAt,
  }) {
    return BadgeAchievement(
      id: 'badge-1',
      familyId: 'family-1',
      badgeKey: key,
      tier: BadgeTier.normal,
      unlockedAt: unlockedAt,
      createdAt: unlockedAt,
    );
  }

  ActivityModel _makeSleep({
    required DateTime start,
    DateTime? end,
  }) {
    return ActivityModel(
      id: 'sleep-${start.millisecondsSinceEpoch}',
      familyId: 'family-1',
      babyIds: ['baby-1'],
      type: ActivityType.sleep,
      startTime: start,
      endTime: end,
      data: const {'sleep_type': 'night'},
      createdAt: DateTime.now(),
    );
  }

  group('EncouragementEngine - Time period', () {
    test('#1 dawn at 03:00', () {
      final now = DateTime(2026, 2, 10, 3, 0);
      final result = EncouragementEngine.select(
        baby: testBaby,
        todayActivities: [],
        recentBadges: [],
        hasPendingBadgePopup: false,
        tone: 'warm',
        now: now,
      );

      expect(result, isNotNull);
      expect(result!.key, contains('dawn'));
    });

    test('#2 morning at 09:00', () {
      final now = DateTime(2026, 2, 10, 9, 0);
      final result = EncouragementEngine.select(
        baby: testBaby,
        todayActivities: [],
        recentBadges: [],
        hasPendingBadgePopup: false,
        tone: 'warm',
        now: now,
      );

      expect(result, isNotNull);
      // Should be morning or general message
      final key = result!.key;
      expect(
        key.contains('morning') || key.contains('general'),
        isTrue,
      );
    });
  });

  group('EncouragementEngine - Badge integration', () {
    test('#3 recent badge (30min ago) returns D6', () {
      final now = DateTime(2026, 2, 10, 14, 0);
      final recentBadge = _makeBadge(
        key: 'first_feeding',
        unlockedAt: now.subtract(const Duration(minutes: 30)),
      );

      final result = EncouragementEngine.select(
        baby: testBaby,
        todayActivities: [],
        recentBadges: [recentBadge],
        hasPendingBadgePopup: false,
        tone: 'warm',
        now: now,
      );

      expect(result, isNotNull);
      expect(result!.key, 'encouragement_data_badge');
      expect(result.tier, EncouragementTier.data);
    });

    test('#4 old badge (2h ago) returns general message', () {
      final now = DateTime(2026, 2, 10, 14, 0);
      final oldBadge = _makeBadge(
        key: 'first_feeding',
        unlockedAt: now.subtract(const Duration(hours: 2)),
      );

      final result = EncouragementEngine.select(
        baby: testBaby,
        todayActivities: [],
        recentBadges: [oldBadge],
        hasPendingBadgePopup: false,
        tone: 'warm',
        now: now,
      );

      expect(result, isNotNull);
      expect(result!.key, isNot('encouragement_data_badge'));
    });

    test('#5 badge popup queued prevents D6', () {
      final now = DateTime(2026, 2, 10, 14, 0);
      final recentBadge = _makeBadge(
        key: 'first_feeding',
        unlockedAt: now.subtract(const Duration(minutes: 10)),
      );

      final result = EncouragementEngine.select(
        baby: testBaby,
        todayActivities: [],
        recentBadges: [recentBadge],
        hasPendingBadgePopup: true, // popup queued
        tone: 'warm',
        now: now,
      );

      expect(result, isNotNull);
      // Should NOT be badge message due to overlap
      expect(result!.key, isNot('encouragement_data_badge'));
    });
  });

  group('EncouragementEngine - Message selection', () {
    test('#6 lastShownKey avoids same message', () {
      final now = DateTime(2026, 2, 10, 3, 0); // dawn
      final result1 = EncouragementEngine.select(
        baby: testBaby,
        todayActivities: [],
        recentBadges: [],
        hasPendingBadgePopup: false,
        tone: 'warm',
        now: now,
      );

      expect(result1, isNotNull);

      final result2 = EncouragementEngine.select(
        baby: testBaby,
        todayActivities: [],
        recentBadges: [],
        hasPendingBadgePopup: false,
        tone: 'warm',
        now: now,
        lastShownMessageKey: result1!.key,
      );

      // Should pick a different message (pool has multiple)
      expect(result2, isNotNull);
      expect(result2!.key, isNot(result1.key));
    });

    test('#7 no activities returns Tier 3 general', () {
      final now = DateTime(2026, 2, 10, 15, 0); // afternoon
      final result = EncouragementEngine.select(
        baby: testBaby,
        todayActivities: [],
        recentBadges: [],
        hasPendingBadgePopup: false,
        tone: 'warm',
        now: now,
      );

      expect(result, isNotNull);
      expect(result!.tier, EncouragementTier.general);
    });
  });

  group('EncouragementEngine - Data-based', () {
    test('#8 night sleep 4h returns D2 sleep message', () {
      final now = DateTime(2026, 2, 10, 9, 0);
      final sleepActivity = _makeSleep(
        start: DateTime(2026, 2, 10, 1, 0),
        end: DateTime(2026, 2, 10, 5, 0), // 4 hours
      );

      final result = EncouragementEngine.select(
        baby: testBaby,
        todayActivities: [sleepActivity],
        recentBadges: [],
        hasPendingBadgePopup: false,
        tone: 'warm',
        now: now,
      );

      expect(result, isNotNull);
      expect(result!.key, 'encouragement_data_sleep');
      expect(result.tier, EncouragementTier.data);
      expect(result.params['hours'], '4.0');
    });
  });
}
