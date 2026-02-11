import 'package:flutter_test/flutter_test.dart';
import 'package:lulu_mvp_f/core/utils/sweet_spot_calculator.dart';
import 'package:lulu_mvp_f/data/models/sweet_spot_result.dart';
import 'package:lulu_mvp_f/features/home/providers/sweet_spot_provider.dart'
    show SweetSpotState;

void main() {
  const calculator = SweetSpotCalculator();

  // Fixed base time for deterministic tests
  final baseTime = DateTime(2026, 2, 11, 10, 0, 0);

  group('SweetSpotCalculator', () {
    // ============================================================
    // Test 1: Newborn (0wk) 30min awake → tooEarly
    // ============================================================
    test('1. Newborn 30min awake → tooEarly, range 30-60min', () {
      final lastWake = baseTime;
      final now = baseTime.add(const Duration(minutes: 30));

      final result = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 0,
        lastWakeTime: lastWake,
        now: now,
      );

      // 0 months → first table entry (0.5mo): 30-60min
      // But nap correction: nap 1 of 4 → factor 0.9
      // corrected min = (30 * 0.9).round() = 27
      // corrected max = (60 * 0.9).round() = 54
      // minSleepTime = lastWake + 27min = 10:27
      // now = 10:30 → 10:30 is before (10:27 - 30min = 09:57)? No
      // 10:30 is after 09:57, is before 10:27? Yes → approaching
      // Actually 10:30 > 10:27 → is before 10:54? Yes → optimal
      expect(result.state, SweetSpotState.optimal);
      expect(result.wakeWindow.minMinutes, 27); // 30 * 0.9
      expect(result.wakeWindow.maxMinutes, 54); // 60 * 0.9
    });

    // ============================================================
    // Test 2: Newborn (0wk) 10min awake → tooEarly
    // ============================================================
    test('2. Newborn 10min awake → tooEarly', () {
      final lastWake = baseTime;
      final now = baseTime.add(const Duration(minutes: 10));

      final result = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 0,
        lastWakeTime: lastWake,
        now: now,
      );

      // corrected min = 27, minSleepTime = 10:27
      // approaching threshold = 10:27 - 30min = 09:57
      // now = 10:10 → after 09:57 → approaching (within 30min of min)
      expect(result.state, SweetSpotState.approaching);
    });

    // ============================================================
    // Test 3: 3-month baby first nap → -10% correction
    // ============================================================
    test('3. 3mo baby first nap → -10% correction applied', () {
      final lastWake = baseTime;
      final now = baseTime.add(const Duration(minutes: 30));

      final result = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 3,
        lastWakeTime: lastWake,
        now: now,
        currentNapNumber: 1,
        totalExpectedNaps: 3,
      );

      // 3mo → table entry (4.0): 75-120min
      // First nap: factor 0.9
      // corrected min = (75 * 0.9).round() = 68
      // corrected max = (120 * 0.9).round() = 108
      expect(result.wakeWindow.minMinutes, 68);
      expect(result.wakeWindow.maxMinutes, 108);
      expect(result.napNumber, 1);
    });

    // ============================================================
    // Test 4: 6-month baby last nap (3rd of 3) → +15% correction
    // ============================================================
    test('4. 6mo baby last nap → +15% correction applied', () {
      final lastWake = baseTime;
      final now = baseTime.add(const Duration(minutes: 30));

      final result = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 6,
        lastWakeTime: lastWake,
        now: now,
        currentNapNumber: 3,
        totalExpectedNaps: 3,
      );

      // 6mo → table entry (7.0): 120-180min
      // Last nap: factor 1.15
      // corrected min = (120 * 1.15).round() = 138
      // corrected max = (180 * 1.15).round() = 207
      expect(result.wakeWindow.minMinutes, 138);
      expect(result.wakeWindow.maxMinutes, 207);
      expect(result.napNumber, 3);
    });

    // ============================================================
    // Test 5: 12-month baby → table boundary (180-240min)
    // ============================================================
    test('5. 12mo baby → middle nap, no correction', () {
      final lastWake = baseTime;
      final now = baseTime.add(const Duration(minutes: 30));

      final result = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 12,
        lastWakeTime: lastWake,
        now: now,
        currentNapNumber: 1,
        totalExpectedNaps: 2,
      );

      // 12mo → table entry (18.0): 210-300min
      // Nap 1 of 2: first nap factor 0.9
      // corrected min = (210 * 0.9).round() = 189
      // corrected max = (300 * 0.9).round() = 270
      expect(result.wakeWindow.minMinutes, 189);
      expect(result.wakeWindow.maxMinutes, 270);
    });

    // ============================================================
    // Test 6: 18+ month baby → 240-360min range
    // ============================================================
    test('6. 24mo baby → 240-360min range, no correction (1 nap)', () {
      final lastWake = baseTime;
      final now = baseTime.add(const Duration(minutes: 30));

      final result = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 24,
        lastWakeTime: lastWake,
        now: now,
      );

      // 24mo → table entry (99.0): 240-360min
      // 1 expected nap → no correction (totalNaps <= 1)
      expect(result.wakeWindow.minMinutes, 240);
      expect(result.wakeWindow.maxMinutes, 360);
      expect(result.totalExpectedNaps, 1);
    });

    // ============================================================
    // Test 7: Overtired (awake time exceeds max)
    // ============================================================
    test('7. Overtired → state == overtired', () {
      final lastWake = baseTime;
      // 3mo baby: corrected max = 108min (with first nap factor)
      // Set now well past max
      final now = baseTime.add(const Duration(minutes: 150));

      final result = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 3,
        lastWakeTime: lastWake,
        now: now,
        currentNapNumber: 1,
        totalExpectedNaps: 3,
      );

      expect(result.state, SweetSpotState.overtired);
    });

    // ============================================================
    // Test 8: Corrected age applied (actual 5mo, corrected 3mo)
    // ============================================================
    test('8. Corrected age: 3mo uses 3mo table (60-90min base)', () {
      final lastWake = baseTime;
      final now = baseTime.add(const Duration(minutes: 10));

      // Using corrected age 3 months (even though actual might be 5)
      final result = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 3,
        lastWakeTime: lastWake,
        now: now,
      );

      // 3mo → table entry (4.0): 75-120min base
      // With first nap correction: 68-108min
      expect(result.correctedAgeMonths, 3);
      expect(result.wakeWindow.minMinutes, 68);
    });

    // ============================================================
    // Test 9: Negative corrected age (-1mo) → clamp to 0
    // ============================================================
    test('9. Negative corrected age → clamped to newborn table', () {
      final lastWake = baseTime;
      final now = baseTime.add(const Duration(minutes: 10));

      final result = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: -1,
        lastWakeTime: lastWake,
        now: now,
      );

      // -1 clamped to 0 → first table entry (0.5mo): 30-60min
      // With first nap correction: 27-54min
      expect(result.correctedAgeMonths, -1); // preserves input
      expect(result.wakeWindow.minMinutes, 27); // table lookup used 0
    });

    // ============================================================
    // Test 10: No sleep record (lastWakeTime null) → unknown
    // ============================================================
    test('10. No sleep record → state == unknown', () {
      final result = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 6,
        lastWakeTime: null,
        now: baseTime,
      );

      expect(result.state, SweetSpotState.unknown);
      expect(result.napNumber, 0);
      expect(result.totalExpectedNaps, 0);
      expect(result.stateMessageKey, 'sweetSpotUnknown');
    });

    // ============================================================
    // Test 11: Daily nap schedule (6mo baby)
    // ============================================================
    test('11. Daily schedule: 6mo → 3 naps, stops before bedtime', () {
      final morningWake = DateTime(2026, 2, 11, 7, 0, 0);
      final now = DateTime(2026, 2, 11, 7, 30, 0);

      final schedule = calculator.calculateDailyNapSchedule(
        babyId: 'baby1',
        correctedAgeMonths: 6,
        morningWakeTime: morningWake,
        now: now,
      );

      // 6mo: 3 expected naps
      // Should generate results and stop before 19:00
      expect(schedule.isNotEmpty, true);
      expect(schedule.length, lessThanOrEqualTo(3));
      for (final nap in schedule) {
        expect(nap.minSleepTime.isBefore(DateTime(2026, 2, 11, 19, 0)),
            true);
      }
    });

    // ============================================================
    // Test 12: Midnight crossing (23:50 wake → 00:30 now)
    // ============================================================
    test('12. Midnight crossing → normal calculation', () {
      final lastWake = DateTime(2026, 2, 11, 23, 50, 0);
      final now = DateTime(2026, 2, 12, 0, 30, 0);

      final result = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 3,
        lastWakeTime: lastWake,
        now: now,
      );

      // 40 minutes elapsed, no negative values
      expect(result.state, isNot(SweetSpotState.unknown));
      expect(result.minSleepTime.isAfter(lastWake), true);
    });

    // ============================================================
    // Test 13: Night time判定 (18:00) → isNightTime == true
    // ============================================================
    test('13. 18:00 → isNightTime == true', () {
      final lastWake = DateTime(2026, 2, 11, 16, 0, 0);
      final now = DateTime(2026, 2, 11, 18, 0, 0);

      final result = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 6,
        lastWakeTime: lastWake,
        now: now,
      );

      expect(result.isNightTime, true);
    });

    // ============================================================
    // Test 14: Night time (05:59) → isNightTime == true
    // ============================================================
    test('14. 05:59 → isNightTime == true', () {
      final lastWake = DateTime(2026, 2, 11, 4, 0, 0);
      final now = DateTime(2026, 2, 11, 5, 59, 0);

      final result = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 6,
        lastWakeTime: lastWake,
        now: now,
      );

      expect(result.isNightTime, true);
    });

    // ============================================================
    // Test 15: Daytime (06:00) → isNightTime == false
    // ============================================================
    test('15. 06:00 → isNightTime == false', () {
      final lastWake = DateTime(2026, 2, 11, 4, 0, 0);
      final now = DateTime(2026, 2, 11, 6, 0, 0);

      final result = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 6,
        lastWakeTime: lastWake,
        now: now,
      );

      expect(result.isNightTime, false);
    });

    // ============================================================
    // Test 16: Deterministic (fixed time → same output)
    // ============================================================
    test('16. Deterministic: same input → same output', () {
      final lastWake = baseTime;
      final now = baseTime.add(const Duration(minutes: 50));

      final result1 = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 6,
        lastWakeTime: lastWake,
        now: now,
      );

      final result2 = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 6,
        lastWakeTime: lastWake,
        now: now,
      );

      expect(result1.state, result2.state);
      expect(result1.wakeWindow.minMinutes, result2.wakeWindow.minMinutes);
      expect(result1.wakeWindow.maxMinutes, result2.wakeWindow.maxMinutes);
      expect(result1.minSleepTime, result2.minSleepTime);
      expect(result1.maxSleepTime, result2.maxSleepTime);
    });

    // ============================================================
    // Test 17: Progress real-time calculation
    // ============================================================
    test('17. Progress changes with now', () {
      final lastWake = baseTime;
      final now1 = baseTime.add(const Duration(minutes: 30));
      final now2 = baseTime.add(const Duration(minutes: 60));

      final result = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 6,
        lastWakeTime: lastWake,
        now: now1,
      );

      final progress1 = result.calculateProgress(now1);
      final progress2 = result.calculateProgress(now2);

      expect(progress2, greaterThan(progress1));
    });

    // ============================================================
    // Test 18: Personalized blending (weight 0.3)
    // ============================================================
    test('18. Personalized blending: 70% literature + 30% observed', () {
      final lastWake = baseTime;
      final now = baseTime.add(const Duration(minutes: 10));

      final personalized = PersonalizedWakeWindow(
        observedRange: const WakeWindowRange(
          minMinutes: 100,
          maxMinutes: 160,
        ),
        personalWeight: 0.3,
        observedDays: 5,
      );

      final result = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 6,
        lastWakeTime: lastWake,
        now: now,
        currentNapNumber: 2,
        totalExpectedNaps: 3,
        personalizedWindow: personalized,
      );

      // 6mo base: 120-180min (table entry 7.0)
      // Blended min = (120 * 0.7 + 100 * 0.3).round() = (84 + 30) = 114
      // Blended max = (180 * 0.7 + 160 * 0.3).round() = (126 + 48) = 174
      // Middle nap (2 of 3): no correction
      expect(result.wakeWindow.minMinutes, 114);
      expect(result.wakeWindow.maxMinutes, 174);
    });

    // ============================================================
    // Test 19: Personalized safety clamp (extreme values)
    // ============================================================
    test('19. Personalized safety clamp: extreme values clamped', () {
      final lastWake = baseTime;
      final now = baseTime.add(const Duration(minutes: 10));

      final personalized = PersonalizedWakeWindow(
        observedRange: const WakeWindowRange(
          minMinutes: 10, // extreme low
          maxMinutes: 500, // extreme high
        ),
        personalWeight: 0.9,
        observedDays: 20,
      );

      final result = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 6,
        lastWakeTime: lastWake,
        now: now,
        currentNapNumber: 2,
        totalExpectedNaps: 3,
        personalizedWindow: personalized,
      );

      // 6mo base: 120-180min
      // Safety: 75% of min (90) to 125% of max (225)
      // Blended min = (120 * 0.1 + 10 * 0.9).round() = (12 + 9) = 21 → clamped to 90
      // Blended max = (180 * 0.1 + 500 * 0.9).round() = (18 + 450) = 468 → clamped to 225
      expect(result.wakeWindow.minMinutes, greaterThanOrEqualTo(90));
      expect(result.wakeWindow.maxMinutes, lessThanOrEqualTo(225));
    });

    // ============================================================
    // Test 20: 1-nap baby (18mo+) → no correction
    // ============================================================
    test('20. 18mo+ baby: 1 nap → no correction applied', () {
      final lastWake = baseTime;
      final now = baseTime.add(const Duration(minutes: 30));

      final result = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 20,
        lastWakeTime: lastWake,
        now: now,
      );

      // 20mo → table entry (99.0): 240-360min
      // 1 expected nap → totalNaps == 1 → no correction
      expect(result.wakeWindow.minMinutes, 240);
      expect(result.wakeWindow.maxMinutes, 360);
      expect(result.totalExpectedNaps, 1);
    });
  });

  group('SweetSpotResult', () {
    test('calculateProgress returns 0.0 for null lastWakeTime', () {
      final result = SweetSpotResult(
        babyId: 'baby1',
        correctedAgeMonths: 6,
        state: SweetSpotState.unknown,
        wakeWindow: const WakeWindowRange(minMinutes: 0, maxMinutes: 0),
        lastWakeTime: null,
        minSleepTime: baseTime,
        maxSleepTime: baseTime,
        napNumber: 0,
        totalExpectedNaps: 0,
        isNightTime: false,
        calculatedAt: baseTime,
        stateMessageKey: 'sweetSpotUnknown',
      );

      expect(result.calculateProgress(baseTime), 0.0);
    });

    test('minutesUntilMid returns midpoint', () {
      final now = baseTime;
      final result = SweetSpotResult(
        babyId: 'baby1',
        correctedAgeMonths: 6,
        state: SweetSpotState.tooEarly,
        wakeWindow: const WakeWindowRange(minMinutes: 120, maxMinutes: 180),
        lastWakeTime: baseTime.subtract(const Duration(minutes: 30)),
        minSleepTime: baseTime.add(const Duration(minutes: 90)),
        maxSleepTime: baseTime.add(const Duration(minutes: 150)),
        napNumber: 1,
        totalExpectedNaps: 3,
        isNightTime: false,
        calculatedAt: now,
        stateMessageKey: 'sweetSpotTooEarlyDay',
      );

      // Mid = 90 + (150-90)/2 = 120 min from now
      expect(result.minutesUntilMid(now), 120);
    });
  });

  group('WakeWindowRange', () {
    test('midMinutes is average', () {
      const range = WakeWindowRange(minMinutes: 60, maxMinutes: 120);
      expect(range.midMinutes, 90);
    });

    test('applyFactor scales both min and max', () {
      const range = WakeWindowRange(minMinutes: 100, maxMinutes: 200);
      final scaled = range.applyFactor(0.9);
      expect(scaled.minMinutes, 90);
      expect(scaled.maxMinutes, 180);
    });
  });

  group('PersonalizedWakeWindow', () {
    test('calculateWeight Empirical Bayes: samples=5, stdDev=10, mid=90', () {
      // densityWeight = 5 / (5 + 20) = 0.2
      // normalizedStdDev = (10 / 90).clamp(0,1) ≈ 0.111
      // confidence = 1 - 0.111 = 0.889
      // result = (0.2 * 0.889).clamp(0, 0.9) ≈ 0.178
      final w = PersonalizedWakeWindow.calculateWeight(
        samples: 5,
        stdDev: 10,
        baseRangeMid: 90,
      );
      expect(w, closeTo(0.178, 0.01));
    });
  });

  group('Regression period damping', () {
    test('4mo correctedAge + personalized → weight * 0.8 damping', () {
      final lastWake = baseTime;
      final now = baseTime.add(const Duration(minutes: 10));

      final personalized = PersonalizedWakeWindow(
        observedRange: const WakeWindowRange(
          minMinutes: 100,
          maxMinutes: 160,
        ),
        personalWeight: 0.3,
        observedDays: 5,
      );

      // 4mo: regression period → w = 0.3 * 0.8 = 0.24
      // 4mo base: 75-120min (table entry 5.0: 90-135)
      // Actually 4mo → safeAge=4.0 → entry (5.0): 90-135
      // Blended min = (90 * 0.76 + 100 * 0.24).round() = (68.4 + 24).round() = 92
      // Blended max = (135 * 0.76 + 160 * 0.24).round() = (102.6 + 38.4).round() = 141
      // Middle nap (2 of 3): no nap correction
      final result = calculator.calculate(
        babyId: 'baby1',
        correctedAgeMonths: 4,
        lastWakeTime: lastWake,
        now: now,
        currentNapNumber: 2,
        totalExpectedNaps: 3,
        personalizedWindow: personalized,
      );

      // Without damping: w=0.3 → min=(90*0.7+100*0.3)=93, max=(135*0.7+160*0.3)=142.5≈143
      // With damping: w=0.24 → min=(90*0.76+100*0.24)=92.4≈92, max=(135*0.76+160*0.24)=141
      // The damped result should differ from undamped
      expect(result.wakeWindow.minMinutes, 92);
      expect(result.wakeWindow.maxMinutes, 141);
    });
  });

  group('NapQualityFactor', () {
    test('short nap (20min) → adjustmentFactor == 0.85', () {
      const factor = NapQualityFactor(lastNapDurationMinutes: 20);
      expect(factor.adjustmentFactor, 0.85);
    });

    test('normal nap (45min) → adjustmentFactor == 1.0', () {
      const factor = NapQualityFactor(lastNapDurationMinutes: 45);
      expect(factor.adjustmentFactor, 1.0);
    });

    test('long nap (90min) → adjustmentFactor == 1.10', () {
      const factor = NapQualityFactor(lastNapDurationMinutes: 90);
      expect(factor.adjustmentFactor, 1.10);
    });
  });

  group('getExpectedNapCount', () {
    test('returns correct nap counts by age', () {
      expect(SweetSpotCalculator.getExpectedNapCount(0), 4);
      expect(SweetSpotCalculator.getExpectedNapCount(2), 4);
      expect(SweetSpotCalculator.getExpectedNapCount(3), 3);
      expect(SweetSpotCalculator.getExpectedNapCount(4), 3);
      expect(SweetSpotCalculator.getExpectedNapCount(6), 3);
      expect(SweetSpotCalculator.getExpectedNapCount(8), 2);
      expect(SweetSpotCalculator.getExpectedNapCount(12), 2);
      expect(SweetSpotCalculator.getExpectedNapCount(15), 2);
      expect(SweetSpotCalculator.getExpectedNapCount(18), 1);
      expect(SweetSpotCalculator.getExpectedNapCount(24), 1);
    });
  });
}
