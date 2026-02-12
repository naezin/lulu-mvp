import 'package:flutter_test/flutter_test.dart';
import 'package:lulu_mvp_f/core/utils/sleep_classifier.dart';
import 'package:lulu_mvp_f/data/models/activity_model.dart';
import 'package:lulu_mvp_f/data/models/baby_type.dart';

void main() {
  /// Helper: create a completed sleep ActivityModel
  ActivityModel makeSleep({
    required DateTime start,
    required DateTime end,
    String sleepType = 'night',
  }) {
    return ActivityModel(
      id: 'sleep-${start.hashCode}',
      familyId: 'fam1',
      babyIds: const ['baby1'],
      type: ActivityType.sleep,
      startTime: start,
      endTime: end,
      data: {'sleep_type': sleepType},
      createdAt: start,
    );
  }

  /// Helper: generate N days of sleep data with one long sleep per day
  /// starting at [nightStartHour] and lasting [nightDurationHours]
  List<ActivityModel> generateDaysOfSleep({
    required int days,
    required DateTime baseDate,
    required int nightStartHour,
    int nightDurationHours = 8,
    int napStartHour = 13,
    int napDurationMinutes = 90,
  }) {
    final records = <ActivityModel>[];
    for (int i = 0; i < days; i++) {
      final day = baseDate.subtract(Duration(days: i));

      // Night sleep (longest — anchor candidate)
      final nightStart = DateTime(day.year, day.month, day.day, nightStartHour);
      final nightEnd = nightStart.add(Duration(hours: nightDurationHours));
      records.add(makeSleep(start: nightStart, end: nightEnd));

      // Nap (shorter)
      final napStart = DateTime(day.year, day.month, day.day, napStartHour);
      final napEnd = napStart.add(Duration(minutes: napDurationMinutes));
      records.add(makeSleep(start: napStart, end: napEnd, sleepType: 'nap'));
    }
    return records;
  }

  group('SleepClassifier', () {
    // ============================================================
    // 1. Cold start: no data → fixed range 21:00~06:00
    // ============================================================
    group('Cold start (no data)', () {
      test('21:00 start → night', () {
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 21, 0),
          recentSleepRecords: const [],
        );
        expect(result, 'night');
      });

      test('23:30 start → night', () {
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 23, 30),
          recentSleepRecords: const [],
        );
        expect(result, 'night');
      });

      test('02:00 start → night (past midnight)', () {
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 2, 0),
          recentSleepRecords: const [],
        );
        expect(result, 'night');
      });

      test('05:59 start → night (boundary)', () {
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 5, 59),
          recentSleepRecords: const [],
        );
        expect(result, 'night');
      });

      test('06:00 start → nap (boundary)', () {
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 6, 0),
          recentSleepRecords: const [],
        );
        expect(result, 'nap');
      });

      test('14:00 start → nap', () {
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 14, 0),
          recentSleepRecords: const [],
        );
        expect(result, 'nap');
      });

      test('20:59 start → nap (just before cold start night)', () {
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 20, 59),
          recentSleepRecords: const [],
        );
        expect(result, 'nap');
      });
    });

    // ============================================================
    // 2. Cold start: insufficient data (< 3 days)
    // ============================================================
    group('Cold start (insufficient data < 3 days)', () {
      test('2 days of data → falls back to cold start', () {
        final baseDate = DateTime(2026, 2, 12);
        final records = generateDaysOfSleep(
          days: 2,
          baseDate: baseDate,
          nightStartHour: 22,
        );

        // 14:00 → nap (cold start)
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 14, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 14, 0),
        );
        expect(result, 'nap');
      });

      test('isColdStart returns true with < 3 days data', () {
        final records = generateDaysOfSleep(
          days: 2,
          baseDate: DateTime(2026, 2, 12),
          nightStartHour: 22,
        );
        expect(SleepClassifier.isColdStart(records), isTrue);
      });
    });

    // ============================================================
    // 3. Pattern-based: anchor = ~22:00
    // ============================================================
    group('Pattern-based (anchor ~22:00)', () {
      late List<ActivityModel> records;

      setUp(() {
        records = generateDaysOfSleep(
          days: 7,
          baseDate: DateTime(2026, 2, 12),
          nightStartHour: 22,
        );
      });

      test('22:00 start → night (at anchor)', () {
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 22, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 22, 0),
        );
        expect(result, 'night');
      });

      test('20:00 start → night (anchor - 2h)', () {
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 20, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 20, 0),
        );
        expect(result, 'night');
      });

      test('23:59 start → night (anchor + ~2h)', () {
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 23, 59),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 23, 59),
        );
        expect(result, 'night');
      });

      test('10:00 start → nap (far from anchor)', () {
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 10, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 10, 0),
        );
        expect(result, 'nap');
      });

      test('14:00 start → nap', () {
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 14, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 14, 0),
        );
        expect(result, 'nap');
      });

      test('isColdStart returns false with 7 days data', () {
        expect(SleepClassifier.isColdStart(records), isFalse);
      });

      test('getNightAnchor returns ~22.0', () {
        final anchor = SleepClassifier.getNightAnchor(records);
        expect(anchor, isNotNull);
        // Anchor should be around 22.0 (all nights start at 22:00)
        expect(anchor!, closeTo(22.0, 0.5));
      });
    });

    // ============================================================
    // 4. Circular wrapping: anchor = ~23:00
    // ============================================================
    group('Circular wrapping (anchor ~23:00)', () {
      late List<ActivityModel> records;

      setUp(() {
        records = generateDaysOfSleep(
          days: 5,
          baseDate: DateTime(2026, 2, 12),
          nightStartHour: 23,
        );
      });

      test('01:00 start → night (wraps past midnight)', () {
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 1, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 1, 0),
        );
        expect(result, 'night');
      });

      test('23:00 start → night (at anchor)', () {
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 23, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 23, 0),
        );
        expect(result, 'night');
      });

      test('12:00 start → nap (far from anchor)', () {
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 12, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 12, 0),
        );
        expect(result, 'nap');
      });
    });

    // ============================================================
    // 5. Early bedtime pattern: anchor = ~19:00
    // ============================================================
    group('Early bedtime (anchor ~19:00)', () {
      late List<ActivityModel> records;

      setUp(() {
        records = generateDaysOfSleep(
          days: 5,
          baseDate: DateTime(2026, 2, 12),
          nightStartHour: 19,
        );
      });

      test('19:00 start → night', () {
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 19, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 19, 0),
        );
        expect(result, 'night');
      });

      test('17:00 start → night (anchor - 2h)', () {
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 17, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 17, 0),
        );
        expect(result, 'night');
      });

      test('10:00 start → nap', () {
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 10, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 10, 0),
        );
        expect(result, 'nap');
      });
    });

    // ============================================================
    // 6. endTime parameter (should not affect classification)
    // ============================================================
    group('endTime parameter', () {
      test('classify uses startTime regardless of endTime', () {
        // Cold start: 22:00 start with endTime 06:00 next day
        final resultWithEnd = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 22, 0),
          endTime: DateTime(2026, 2, 13, 6, 0),
          recentSleepRecords: const [],
        );
        final resultWithoutEnd = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 22, 0),
          recentSleepRecords: const [],
        );
        expect(resultWithEnd, resultWithoutEnd);
        expect(resultWithEnd, 'night');
      });
    });

    // ============================================================
    // 7. Only returns 'nap' or 'night'
    // ============================================================
    group('Return value contract', () {
      test('always returns nap or night', () {
        for (int hour = 0; hour < 24; hour++) {
          final result = SleepClassifier.classify(
            startTime: DateTime(2026, 2, 12, hour, 0),
            recentSleepRecords: const [],
          );
          expect(result, anyOf('nap', 'night'),
              reason: 'hour $hour should return nap or night');
        }
      });
    });

    // ============================================================
    // 8. Filters out non-sleep and incomplete records
    // ============================================================
    group('Record filtering', () {
      test('ignores non-sleep records', () {
        final mixedRecords = [
          // Feeding record (should be ignored)
          ActivityModel(
            id: 'feed1',
            familyId: 'fam1',
            babyIds: const ['baby1'],
            type: ActivityType.feeding,
            startTime: DateTime(2026, 2, 11, 22, 0),
            endTime: DateTime(2026, 2, 11, 22, 30),
            data: const {'feeding_type': 'bottle'},
            createdAt: DateTime(2026, 2, 11),
          ),
          // Incomplete sleep (no endTime — should be ignored)
          ActivityModel(
            id: 'sleep-ongoing',
            familyId: 'fam1',
            babyIds: const ['baby1'],
            type: ActivityType.sleep,
            startTime: DateTime(2026, 2, 11, 22, 0),
            data: const {'sleep_type': 'night'},
            createdAt: DateTime(2026, 2, 11),
          ),
        ];

        // With only non-qualifying records → cold start
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 22, 0),
          recentSleepRecords: mixedRecords,
        );
        // Should fall back to cold start (22:00 → night)
        expect(result, 'night');
        expect(SleepClassifier.isColdStart(mixedRecords), isTrue);
      });
    });
  });
}
