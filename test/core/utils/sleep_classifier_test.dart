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

      test('20:00 start → nap (outside density window, sleep starts at 22:00)', () {
        // v2: nightWindow is based on actual sleep density (22:00~06:00)
        // 20:00 has no sleep density → classified as nap (correct behavior)
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 20, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 20, 0),
        );
        expect(result, 'nap');
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

      test('getNightWindow covers ~22:00 start', () {
        final window = SleepClassifier.getNightWindow(records,
            now: DateTime(2026, 2, 12, 23, 0));
        expect(window, isNotNull);
        // Night window should contain bin 44 (22:00)
        // bin 44 = hour 22 * 2 + 0 = 44
        expect(window!.contains(44), isTrue);
        // Night window should NOT contain bin 28 (14:00)
        expect(window.contains(28), isFalse);
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

      test('17:00 start → nap (outside density window, sleep starts at 19:00)', () {
        // v2: nightWindow based on actual density (19:00~03:00)
        // 17:00 has no sleep density → nap (correct behavior)
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 17, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 17, 0),
        );
        expect(result, 'nap');
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

    group('effectiveSleepType', () {
      test('returns existing sleep_type when present', () {
        final activity = _makeSleep(
          DateTime(2026, 2, 12, 10, 0),
          DateTime(2026, 2, 12, 11, 0),
          data: {'sleep_type': 'night'},
        );
        expect(SleepClassifier.effectiveSleepType(activity), 'night');
      });

      test('classifies as nap when sleep_type is NULL and daytime', () {
        final activity = _makeSleep(
          DateTime(2026, 2, 12, 14, 0),
          DateTime(2026, 2, 12, 15, 0),
        );
        // No data → cold start → 14:00 = nap
        expect(SleepClassifier.effectiveSleepType(activity), 'nap');
      });

      test('classifies as night when sleep_type is NULL and nighttime', () {
        final activity = _makeSleep(
          DateTime(2026, 2, 12, 22, 0),
          DateTime(2026, 2, 13, 6, 0),
        );
        // No data → cold start → 22:00 = night
        expect(SleepClassifier.effectiveSleepType(activity), 'night');
      });

      test('classifies as nap when sleep_type is empty string', () {
        final activity = _makeSleep(
          DateTime(2026, 2, 12, 14, 0),
          DateTime(2026, 2, 12, 15, 0),
          data: {'sleep_type': ''},
        );
        // Empty string → treated as missing → cold start → 14:00 = nap
        expect(SleepClassifier.effectiveSleepType(activity), 'nap');
      });

      test('uses recentSleepRecords for pattern-based fallback', () {
        final recentRecords = List.generate(7, (i) {
          final day = DateTime(2026, 2, 5 + i);
          return _makeSleep(
            DateTime(day.year, day.month, day.day, 20, 0),
            DateTime(day.year, day.month, day.day + 1, 5, 0),
          );
        });

        // 20:30 is within density window (20:00~05:00) and 2h duration → night
        final activity = _makeSleep(
          DateTime(2026, 2, 12, 20, 30),
          DateTime(2026, 2, 12, 22, 30),
        );
        final result = SleepClassifier.effectiveSleepType(
          activity,
          recentSleepRecords: recentRecords,
        );
        expect(result, 'night');
      });
    });

    group('applyFallbackSleepTypes', () {
      test('adds sleep_type to records missing it', () {
        final activities = [
          _makeSleep(
            DateTime(2026, 2, 12, 14, 0),
            DateTime(2026, 2, 12, 15, 0),
          ),
          _makeSleep(
            DateTime(2026, 2, 12, 22, 0),
            DateTime(2026, 2, 13, 6, 0),
          ),
        ];

        final result = SleepClassifier.applyFallbackSleepTypes(activities);
        expect(result[0].data?['sleep_type'], 'nap');
        expect(result[1].data?['sleep_type'], 'night');
      });

      test('preserves existing sleep_type', () {
        final activities = [
          _makeSleep(
            DateTime(2026, 2, 12, 14, 0),
            DateTime(2026, 2, 12, 15, 0),
            data: {'sleep_type': 'night'}, // Override: daytime but marked night
          ),
        ];

        final result = SleepClassifier.applyFallbackSleepTypes(activities);
        expect(result[0].data?['sleep_type'], 'night'); // Preserved
      });

      test('skips non-sleep activities', () {
        final feeding = ActivityModel(
          id: 'f1',
          familyId: 'fam1',
          babyIds: ['baby1'],
          type: ActivityType.feeding,
          startTime: DateTime(2026, 2, 12, 10, 0),
          createdAt: DateTime(2026, 2, 12),
          data: {'feeding_type': 'breast'},
        );

        final result = SleepClassifier.applyFallbackSleepTypes([feeding]);
        expect(result[0].data?['sleep_type'], isNull);
        expect(result[0].data?['feeding_type'], 'breast');
      });
    });

    // ============================================================
    // v2: Night Window construction
    // ============================================================
    group('v2 Night Window construction', () {
      test('7 days 20:00~06:00 pattern builds window containing 20:00~06:00',
          () {
        final records = generateDaysOfSleep(
          days: 7,
          baseDate: DateTime(2026, 2, 12),
          nightStartHour: 20,
          nightDurationHours: 10,
        );
        final window = SleepClassifier.getNightWindow(records,
            now: DateTime(2026, 2, 12, 23, 0));
        expect(window, isNotNull);
        // bin 40 = 20:00, bin 12 = 06:00
        expect(window!.contains(40), isTrue, reason: '20:00 should be in window');
        expect(window.contains(0), isTrue, reason: '00:00 should be in window');
        expect(window.contains(12), isTrue, reason: '06:00 should be in window');
        expect(window.contains(28), isFalse, reason: '14:00 should be outside');
      });

      test('7 days 19:00~05:00 pattern builds window containing 19:00~05:00',
          () {
        final records = generateDaysOfSleep(
          days: 7,
          baseDate: DateTime(2026, 2, 12),
          nightStartHour: 19,
          nightDurationHours: 10,
        );
        final window = SleepClassifier.getNightWindow(records,
            now: DateTime(2026, 2, 12, 23, 0));
        expect(window, isNotNull);
        // bin 38 = 19:00
        expect(window!.contains(38), isTrue, reason: '19:00 in window');
        expect(window.contains(10), isTrue, reason: '05:00 in window');
        expect(window.contains(30), isFalse, reason: '15:00 outside');
      });

      test('midnight crossing handled naturally', () {
        final records = generateDaysOfSleep(
          days: 7,
          baseDate: DateTime(2026, 2, 12),
          nightStartHour: 23,
          nightDurationHours: 8,
        );
        final window = SleepClassifier.getNightWindow(records,
            now: DateTime(2026, 2, 12, 23, 0));
        expect(window, isNotNull);
        // Wraps midnight: startBin > endBin
        expect(window!.startBin > window.endBin, isTrue,
            reason: 'Night window should wrap midnight');
        // bin 46 = 23:00, bin 14 = 07:00
        expect(window.contains(46), isTrue, reason: '23:00 in window');
        expect(window.contains(0), isTrue, reason: '00:00 in window');
        expect(window.contains(14), isTrue, reason: '07:00 in window');
        expect(window.contains(30), isFalse, reason: '15:00 outside');
      });

      test('fewer than 3 days returns null', () {
        final records = generateDaysOfSleep(
          days: 2,
          baseDate: DateTime(2026, 2, 12),
          nightStartHour: 22,
        );
        final window = SleepClassifier.getNightWindow(records,
            now: DateTime(2026, 2, 12, 23, 0));
        expect(window, isNull);
      });

      test('recency weight: recent 7 days data weighs more than 8-14 days',
          () {
        // 8-14 days ago: sleep at 22:00~06:00
        // 1-7 days ago: sleep at 20:00~04:00
        // Recent data should dominate the window
        final records = <ActivityModel>[];
        for (int i = 8; i <= 14; i++) {
          final day = DateTime(2026, 2, 12).subtract(Duration(days: i));
          records.add(makeSleep(
            start: DateTime(day.year, day.month, day.day, 22, 0),
            end: DateTime(day.year, day.month, day.day + 1, 6, 0),
          ));
        }
        for (int i = 1; i <= 7; i++) {
          final day = DateTime(2026, 2, 12).subtract(Duration(days: i));
          records.add(makeSleep(
            start: DateTime(day.year, day.month, day.day, 20, 0),
            end: DateTime(day.year, day.month, day.day + 1, 4, 0),
          ));
        }
        final window = SleepClassifier.getNightWindow(records,
            now: DateTime(2026, 2, 12, 23, 0));
        expect(window, isNotNull);
        // bin 40 = 20:00 should be included (recent data dominates)
        expect(window!.contains(40), isTrue,
            reason: '20:00 should be in window (recent data dominance)');
      });
    });

    // ============================================================
    // v2: Split Night core cases (v2 raison d'etre)
    // ============================================================
    group('v2 Split Night core cases', () {
      /// Helper: generate split night data
      /// Each night has 2 chunks with a gap in between
      List<ActivityModel> generateSplitNights({
        required int days,
        required DateTime baseDate,
        required int chunk1StartHour,
        required int chunk1DurationHours,
        required int chunk2StartHour,
        required int chunk2DurationHours,
        int napStartHour = 13,
        int napDurationMinutes = 90,
      }) {
        final records = <ActivityModel>[];
        for (int i = 0; i < days; i++) {
          final day = baseDate.subtract(Duration(days: i));

          // Chunk 1
          final c1Start =
              DateTime(day.year, day.month, day.day, chunk1StartHour);
          final c1End = c1Start.add(Duration(hours: chunk1DurationHours));
          records.add(makeSleep(start: c1Start, end: c1End));

          // Chunk 2 (often crosses midnight)
          DateTime c2Start;
          if (chunk2StartHour < chunk1StartHour) {
            // Next calendar day
            final nextDay = day.add(const Duration(days: 1));
            c2Start =
                DateTime(nextDay.year, nextDay.month, nextDay.day, chunk2StartHour);
          } else {
            c2Start =
                DateTime(day.year, day.month, day.day, chunk2StartHour);
          }
          final c2End = c2Start.add(Duration(hours: chunk2DurationHours));
          records.add(makeSleep(start: c2Start, end: c2End));

          // Nap
          final napStart =
              DateTime(day.year, day.month, day.day, napStartHour);
          final napEnd =
              napStart.add(Duration(minutes: napDurationMinutes));
          records.add(makeSleep(
              start: napStart, end: napEnd, sleepType: 'nap'));
        }
        return records;
      }

      test(
          'CORE: 20:00-02:00 + 03:00-06:00 split night — both chunks in window → night',
          () {
        // This is THE scenario that broke v1:
        // v1 picked "longest chunk" per day as anchor, causing 02:00 contamination
        // v2 merges both chunks into same density cluster
        final records = generateSplitNights(
          days: 7,
          baseDate: DateTime(2026, 2, 12),
          chunk1StartHour: 20,
          chunk1DurationHours: 6, // 20:00~02:00
          chunk2StartHour: 3,
          chunk2DurationHours: 3, // 03:00~06:00
        );

        final now = DateTime(2026, 2, 13, 12, 0);

        // Verify night window covers entire 20:00~06:00 range
        final window = SleepClassifier.getNightWindow(records, now: now);
        expect(window, isNotNull);
        expect(window!.contains(40), isTrue, reason: '20:00 in window');
        expect(window.contains(0), isTrue, reason: '00:00 in window');
        expect(window.contains(6), isTrue, reason: '03:00 in window');
        expect(window.contains(12), isTrue, reason: '06:00 in window');

        // New sleep at 20:15 → night
        final result1 = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 13, 20, 15),
          endTime: DateTime(2026, 2, 14, 2, 0),
          recentSleepRecords: records,
          now: now,
        );
        expect(result1, 'night', reason: 'Chunk 1 start → night');

        // New sleep at 03:30 → night (split night 2nd chunk)
        final result2 = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 13, 3, 30),
          endTime: DateTime(2026, 2, 13, 6, 0),
          recentSleepRecords: records,
          now: now,
        );
        expect(result2, 'night', reason: 'Chunk 2 start → night');

        // 13:00 nap → still nap
        final result3 = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 13, 13, 0),
          endTime: DateTime(2026, 2, 13, 14, 30),
          recentSleepRecords: records,
          now: now,
        );
        expect(result3, 'nap', reason: 'Daytime → nap');
      });

      test(
          'CORE: split night chunk lengths vary daily — anchor stays stable',
          () {
        // Day 1: 20:00-01:00 (5h) + 02:00-06:00 (4h)
        // Day 2: 20:30-03:00 (6.5h) + 04:00-06:30 (2.5h)
        // Day 3: 19:45-02:30 (6.75h) + 03:30-05:45 (2.25h)
        // v1: longest chunk swings between 20:00 and 02:00 start times
        // v2: all chunks contribute to 19:45~06:30 density → stable window
        final records = <ActivityModel>[];

        // Day 1
        records.add(makeSleep(
          start: DateTime(2026, 2, 11, 20, 0),
          end: DateTime(2026, 2, 12, 1, 0),
        ));
        records.add(makeSleep(
          start: DateTime(2026, 2, 12, 2, 0),
          end: DateTime(2026, 2, 12, 6, 0),
        ));
        records.add(makeSleep(
          start: DateTime(2026, 2, 11, 13, 0),
          end: DateTime(2026, 2, 11, 14, 30),
          sleepType: 'nap',
        ));

        // Day 2
        records.add(makeSleep(
          start: DateTime(2026, 2, 10, 20, 30),
          end: DateTime(2026, 2, 11, 3, 0),
        ));
        records.add(makeSleep(
          start: DateTime(2026, 2, 11, 4, 0),
          end: DateTime(2026, 2, 11, 6, 30),
        ));
        records.add(makeSleep(
          start: DateTime(2026, 2, 10, 13, 0),
          end: DateTime(2026, 2, 10, 14, 30),
          sleepType: 'nap',
        ));

        // Day 3
        records.add(makeSleep(
          start: DateTime(2026, 2, 9, 19, 45),
          end: DateTime(2026, 2, 10, 2, 30),
        ));
        records.add(makeSleep(
          start: DateTime(2026, 2, 10, 3, 30),
          end: DateTime(2026, 2, 10, 5, 45),
        ));
        records.add(makeSleep(
          start: DateTime(2026, 2, 9, 13, 0),
          end: DateTime(2026, 2, 9, 14, 30),
          sleepType: 'nap',
        ));

        final now = DateTime(2026, 2, 12, 12, 0);
        final window = SleepClassifier.getNightWindow(records, now: now);
        expect(window, isNotNull);

        // Window should cover ~19:45 to ~06:30
        // bin 39 = 19:30, bin 40 = 20:00, bin 13 = 06:30
        expect(window!.contains(40), isTrue, reason: '20:00 in window');
        expect(window.contains(4), isTrue, reason: '02:00 in window');
        expect(window.contains(12), isTrue, reason: '06:00 in window');

        // 20:00 start should be night (not nap like v1 might produce)
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 20, 0),
          endTime: DateTime(2026, 2, 13, 1, 30),
          recentSleepRecords: records,
          now: now,
        );
        expect(result, 'night');
      });

      test(
          'CORE: 03:00 sleep start in split night pattern → night (v1 misclassified as nap)',
          () {
        // v1 failure: anchor at ~20:00, 03:00 is "too far" → nap
        // v2: 03:00 is inside nightWindow (20:00~06:00) → night
        final records = generateSplitNights(
          days: 7,
          baseDate: DateTime(2026, 2, 12),
          chunk1StartHour: 20,
          chunk1DurationHours: 5, // 20:00~01:00
          chunk2StartHour: 3,
          chunk2DurationHours: 3, // 03:00~06:00
        );

        final now = DateTime(2026, 2, 13, 12, 0);

        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 13, 3, 0),
          endTime: DateTime(2026, 2, 13, 6, 0),
          recentSleepRecords: records,
          now: now,
        );
        expect(result, 'night',
            reason: '03:00 is inside nightWindow despite being far from 20:00 start');
      });
    });

    // ============================================================
    // v2: Cluster classification details
    // ============================================================
    group('v2 Cluster classification', () {
      test('nightWindow start + 2h sleep → night', () {
        final records = generateDaysOfSleep(
          days: 7,
          baseDate: DateTime(2026, 2, 12),
          nightStartHour: 21,
          nightDurationHours: 9,
        );
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 21, 30),
          endTime: DateTime(2026, 2, 12, 23, 30),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 23, 30),
        );
        expect(result, 'night');
      });

      test('nightWindow start + 20min sleep → nap (< 30min threshold)', () {
        final records = generateDaysOfSleep(
          days: 7,
          baseDate: DateTime(2026, 2, 12),
          nightStartHour: 21,
          nightDurationHours: 9,
        );
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 22, 0),
          endTime: DateTime(2026, 2, 12, 22, 20),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 22, 20),
        );
        expect(result, 'nap', reason: '< 30min in night window = micro-nap');
      });

      test('outside nightWindow + 6h sleep → nap', () {
        final records = generateDaysOfSleep(
          days: 7,
          baseDate: DateTime(2026, 2, 12),
          nightStartHour: 21,
          nightDurationHours: 9,
        );
        // 10:00~16:00 (6h) but outside window
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 10, 0),
          endTime: DateTime(2026, 2, 12, 16, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 16, 0),
        );
        expect(result, 'nap', reason: 'Long sleep outside nightWindow = nap');
      });

      test('nightWindow boundary bin — exact start → night', () {
        final records = generateDaysOfSleep(
          days: 7,
          baseDate: DateTime(2026, 2, 12),
          nightStartHour: 21,
          nightDurationHours: 9,
        );
        // 21:00 = exact start of density → should be night
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 21, 0),
          endTime: DateTime(2026, 2, 13, 5, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 21, 0),
        );
        expect(result, 'night');
      });
    });

    // ============================================================
    // v2: Multiple births (independent per baby)
    // ============================================================
    group('v2 Multiple births independence', () {
      test('baby A and baby B have different nightWindows', () {
        // Baby A: sleeps 19:30~05:30
        final babyARecords = <ActivityModel>[];
        for (int i = 0; i < 7; i++) {
          final day = DateTime(2026, 2, 12).subtract(Duration(days: i));
          babyARecords.add(ActivityModel(
            id: 'a-night-$i',
            familyId: 'fam1',
            babyIds: const ['babyA'],
            type: ActivityType.sleep,
            startTime: DateTime(day.year, day.month, day.day, 19, 30),
            endTime: DateTime(day.year, day.month, day.day + 1, 5, 30),
            data: const {'sleep_type': 'night'},
            createdAt: day,
          ));
        }

        // Baby B: sleeps 20:30~06:30
        final babyBRecords = <ActivityModel>[];
        for (int i = 0; i < 7; i++) {
          final day = DateTime(2026, 2, 12).subtract(Duration(days: i));
          babyBRecords.add(ActivityModel(
            id: 'b-night-$i',
            familyId: 'fam1',
            babyIds: const ['babyB'],
            type: ActivityType.sleep,
            startTime: DateTime(day.year, day.month, day.day, 20, 30),
            endTime: DateTime(day.year, day.month, day.day + 1, 6, 30),
            data: const {'sleep_type': 'night'},
            createdAt: day,
          ));
        }

        final windowA = SleepClassifier.getNightWindow(babyARecords,
            now: DateTime(2026, 2, 12, 23, 0));
        final windowB = SleepClassifier.getNightWindow(babyBRecords,
            now: DateTime(2026, 2, 12, 23, 0));

        expect(windowA, isNotNull);
        expect(windowB, isNotNull);

        // Baby A's window should contain 19:30 (bin 39)
        expect(windowA!.contains(39), isTrue,
            reason: 'Baby A 19:30 in window');
        // Baby B's window should contain 20:30 (bin 41)
        expect(windowB!.contains(41), isTrue,
            reason: 'Baby B 20:30 in window');

        // Independent classification
        // 20:00 for baby A → could be night (in A's window)
        final resultA = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 20, 0),
          endTime: DateTime(2026, 2, 13, 5, 0),
          recentSleepRecords: babyARecords,
          now: DateTime(2026, 2, 12, 20, 0),
        );
        expect(resultA, 'night', reason: 'Baby A: 20:00 in window');
      });
    });

    // ============================================================
    // v2: Ongoing sleep ("sleep now" mode)
    // ============================================================
    group('v2 Ongoing sleep', () {
      test('nightWindow start + endTime null → night (assume night)', () {
        final records = generateDaysOfSleep(
          days: 7,
          baseDate: DateTime(2026, 2, 12),
          nightStartHour: 21,
          nightDurationHours: 9,
        );
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 21, 30),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 21, 30),
        );
        expect(result, 'night');
      });

      test('outside nightWindow + endTime null → nap', () {
        final records = generateDaysOfSleep(
          days: 7,
          baseDate: DateTime(2026, 2, 12),
          nightStartHour: 21,
          nightDurationHours: 9,
        );
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 14, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 14, 0),
        );
        expect(result, 'nap');
      });
    });

    // ============================================================
    // v2: Edge cases
    // ============================================================
    group('v2 Edge cases', () {
      test('all sleeps similar length — densest zone becomes night', () {
        // 4h night sleep + 3h nap — not obvious which is "longest"
        // But night density at 22:00~02:00 is consistent across days
        final records = <ActivityModel>[];
        for (int i = 0; i < 7; i++) {
          final day = DateTime(2026, 2, 12).subtract(Duration(days: i));
          // "Night": 22:00~02:00 (4h)
          records.add(makeSleep(
            start: DateTime(day.year, day.month, day.day, 22, 0),
            end: DateTime(day.year, day.month, day.day + 1, 2, 0),
          ));
          // "Nap": 13:00~16:00 (3h)
          records.add(makeSleep(
            start: DateTime(day.year, day.month, day.day, 13, 0),
            end: DateTime(day.year, day.month, day.day, 16, 0),
            sleepType: 'nap',
          ));
        }

        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 22, 30),
          endTime: DateTime(2026, 2, 13, 2, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 13, 12, 0),
        );
        expect(result, 'night',
            reason: '22:00~02:00 has higher density → night');
      });

      test('only 1 sleep per day for 3 days — still classifies', () {
        final records = <ActivityModel>[];
        for (int i = 0; i < 3; i++) {
          final day = DateTime(2026, 2, 12).subtract(Duration(days: i));
          records.add(makeSleep(
            start: DateTime(day.year, day.month, day.day, 21, 0),
            end: DateTime(day.year, day.month, day.day + 1, 5, 0),
          ));
        }

        final window = SleepClassifier.getNightWindow(records,
            now: DateTime(2026, 2, 12, 23, 0));
        expect(window, isNotNull, reason: '3 days is minimum');

        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 21, 30),
          endTime: DateTime(2026, 2, 13, 5, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 21, 30),
        );
        expect(result, 'night');
      });

      test('14-day-old data only (no recent 7 days) — still works with lower weight',
          () {
        final records = <ActivityModel>[];
        for (int i = 8; i <= 14; i++) {
          final day = DateTime(2026, 2, 12).subtract(Duration(days: i));
          records.add(makeSleep(
            start: DateTime(day.year, day.month, day.day, 21, 0),
            end: DateTime(day.year, day.month, day.day + 1, 5, 0),
          ));
        }

        final window = SleepClassifier.getNightWindow(records,
            now: DateTime(2026, 2, 12, 23, 0));
        expect(window, isNotNull,
            reason: '7 days of data (older) still builds window');

        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 22, 0),
          endTime: DateTime(2026, 2, 13, 5, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 12, 22, 0),
        );
        expect(result, 'night');
      });

      test('stress test: 100 sleep records classifies without error', () {
        final records = <ActivityModel>[];
        for (int i = 0; i < 14; i++) {
          final day = DateTime(2026, 2, 12).subtract(Duration(days: i));
          // Night in 2 chunks (split night)
          records.add(makeSleep(
            start: DateTime(day.year, day.month, day.day, 20, 0),
            end: DateTime(day.year, day.month, day.day + 1, 1, 0),
          ));
          records.add(makeSleep(
            start: DateTime(day.year, day.month, day.day + 1, 2, 0),
            end: DateTime(day.year, day.month, day.day + 1, 6, 0),
          ));
          // 3 naps
          records.add(makeSleep(
            start: DateTime(day.year, day.month, day.day, 9, 0),
            end: DateTime(day.year, day.month, day.day, 10, 0),
            sleepType: 'nap',
          ));
          records.add(makeSleep(
            start: DateTime(day.year, day.month, day.day, 12, 0),
            end: DateTime(day.year, day.month, day.day, 13, 30),
            sleepType: 'nap',
          ));
          records.add(makeSleep(
            start: DateTime(day.year, day.month, day.day, 15, 0),
            end: DateTime(day.year, day.month, day.day, 16, 0),
            sleepType: 'nap',
          ));
        }
        // 14 days × 5 records = 70 records

        expect(records.length, greaterThanOrEqualTo(70));

        // Should classify without error
        final result = SleepClassifier.classify(
          startTime: DateTime(2026, 2, 12, 20, 30),
          endTime: DateTime(2026, 2, 13, 1, 0),
          recentSleepRecords: records,
          now: DateTime(2026, 2, 13, 12, 0),
        );
        expect(result, anyOf('nap', 'night'));
        // Specifically, 20:30 should be night (in split-night density)
        expect(result, 'night');
      });
    });

    // ============================================================
    // v2: NightWindow model
    // ============================================================
    group('v2 NightWindow model', () {
      test('contains — no midnight wrap', () {
        // Window from 14:00 (bin 28) to 18:00 (bin 36)
        const window = NightWindow(startBin: 28, endBin: 36);
        expect(window.contains(28), isTrue);
        expect(window.contains(32), isTrue);
        expect(window.contains(36), isTrue);
        expect(window.contains(27), isFalse);
        expect(window.contains(37), isFalse);
        expect(window.contains(0), isFalse);
      });

      test('contains — midnight wrap', () {
        // Window from 20:00 (bin 40) to 06:00 (bin 12)
        const window = NightWindow(startBin: 40, endBin: 12);
        expect(window.contains(40), isTrue, reason: '20:00');
        expect(window.contains(44), isTrue, reason: '22:00');
        expect(window.contains(47), isTrue, reason: '23:30');
        expect(window.contains(0), isTrue, reason: '00:00');
        expect(window.contains(6), isTrue, reason: '03:00');
        expect(window.contains(12), isTrue, reason: '06:00');
        expect(window.contains(13), isFalse, reason: '06:30');
        expect(window.contains(39), isFalse, reason: '19:30');
        expect(window.contains(28), isFalse, reason: '14:00');
      });

      test('binCount — no wrap', () {
        const window = NightWindow(startBin: 10, endBin: 20);
        expect(window.binCount, 11);
      });

      test('binCount — midnight wrap', () {
        const window = NightWindow(startBin: 40, endBin: 12);
        // 40..47 = 8 bins + 0..12 = 13 bins = 21 total
        expect(window.binCount, 21);
      });

      test('startHour and endHour', () {
        const window = NightWindow(startBin: 40, endBin: 12);
        expect(window.startHour, 20.0); // bin 40 = 20:00
        expect(window.endHour, 6.5); // bin 12 → (12+1)*0.5 = 6.5
      });

      test('toString format', () {
        const window = NightWindow(startBin: 40, endBin: 12);
        expect(window.toString(), 'NightWindow(20:00 ~ 06:00)');
      });

      test('equality', () {
        const a = NightWindow(startBin: 40, endBin: 12);
        const b = NightWindow(startBin: 40, endBin: 12);
        const c = NightWindow(startBin: 40, endBin: 13);
        expect(a, equals(b));
        expect(a, isNot(equals(c)));
        expect(a.hashCode, equals(b.hashCode));
      });
    });
  });
}

/// Helper to create a sleep ActivityModel for testing
ActivityModel _makeSleep(
  DateTime start,
  DateTime end, {
  Map<String, dynamic>? data,
}) {
  return ActivityModel(
    id: 'sleep_${start.millisecondsSinceEpoch}',
    familyId: 'fam1',
    babyIds: ['baby1'],
    type: ActivityType.sleep,
    startTime: start,
    endTime: end,
    createdAt: start,
    data: data,
  );
}
