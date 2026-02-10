import 'package:flutter_test/flutter_test.dart';
import 'package:lulu_mvp_f/features/record/providers/feeding_record_provider.dart';
import 'package:lulu_mvp_f/features/record/providers/sleep_record_provider.dart';
import 'package:lulu_mvp_f/features/record/providers/diaper_record_provider.dart';
import 'package:lulu_mvp_f/features/record/providers/play_record_provider.dart';
import 'package:lulu_mvp_f/features/record/providers/health_record_provider.dart';
import 'package:lulu_mvp_f/data/models/baby_model.dart';
import 'package:lulu_mvp_f/data/models/baby_type.dart';

/// Record Provider unit tests
///
/// Sprint 21 Phase 2-2: Updated for 5-way split
void main() {
  late List<BabyModel> testBabies;

  setUp(() {
    testBabies = [
      BabyModel(
        id: 'baby1',
        familyId: 'test-family',
        name: 'Baby1',
        birthDate: DateTime.now().subtract(const Duration(days: 60)),
        gestationalWeeksAtBirth: 34,
        birthWeightGrams: 2200,
        multipleBirthType: BabyType.twin,
        birthOrder: 1,
        createdAt: DateTime.now(),
      ),
      BabyModel(
        id: 'baby2',
        familyId: 'test-family',
        name: 'Baby2',
        birthDate: DateTime.now().subtract(const Duration(days: 60)),
        gestationalWeeksAtBirth: 34,
        birthWeightGrams: 2100,
        multipleBirthType: BabyType.twin,
        birthOrder: 2,
        createdAt: DateTime.now(),
      ),
    ];
  });

  group('FeedingRecordProvider', () {
    late FeedingRecordProvider provider;

    setUp(() {
      provider = FeedingRecordProvider();
      provider.initialize(
        familyId: 'test-family',
        babies: testBabies,
      );
    });

    test('initialize sets defaults correctly', () {
      expect(provider.familyId, 'test-family');
      expect(provider.babies.length, 2);
      expect(provider.selectedBabyIds.length, 1);
      expect(provider.selectedBabyId, 'baby1');
      expect(provider.isSelectionValid, true);
    });

    test('preselectedBabyId selects the correct baby', () {
      provider.initialize(
        familyId: 'test-family',
        babies: testBabies,
        preselectedBabyId: 'baby2',
      );
      expect(provider.selectedBabyId, 'baby2');
    });

    test('baby selection change works', () {
      provider.setSelectedBabyIds(['baby2']);
      expect(provider.selectedBabyId, 'baby2');
    });

    test('feeding type change works', () {
      expect(provider.feedingType, 'breast');
      provider.setFeedingType('bottle');
      expect(provider.feedingType, 'bottle');
      provider.setFeedingType('formula');
      expect(provider.feedingType, 'formula');
      provider.setFeedingType('solid');
      expect(provider.feedingType, 'solid');
    });

    test('feeding amount change works', () {
      expect(provider.feedingAmount, 0);
      provider.setFeedingAmount(120);
      expect(provider.feedingAmount, 120);
      provider.setFeedingAmount(150);
      expect(provider.feedingAmount, 150);
    });

    test('breast side change works', () {
      expect(provider.breastSide, 'left');
      provider.setBreastSide('right');
      expect(provider.breastSide, 'right');
      provider.setBreastSide('both');
      expect(provider.breastSide, 'both');
    });

    test('feeding duration change works', () {
      expect(provider.feedingDuration, 0);
      provider.setFeedingDuration(15);
      expect(provider.feedingDuration, 15);
    });

    test('record time change works', () {
      final newTime = DateTime(2026, 1, 30, 14, 30);
      provider.setRecordTime(newTime);
      expect(provider.recordTime, newTime);
    });

    test('notes change works', () {
      expect(provider.notes, null);
      provider.setNotes('test note');
      expect(provider.notes, 'test note');
      provider.setNotes('  ');
      expect(provider.notes, null);
    });
  });

  group('SleepRecordProvider', () {
    late SleepRecordProvider provider;

    setUp(() {
      provider = SleepRecordProvider();
      provider.initialize(
        familyId: 'test-family',
        babies: testBabies,
      );
    });

    test('sleep type change works', () {
      expect(provider.sleepType, 'nap');
      provider.setSleepType('night');
      expect(provider.sleepType, 'night');
    });

    test('sleep start/end time change works', () {
      final startTime = DateTime(2026, 1, 30, 10, 0);
      final endTime = DateTime(2026, 1, 30, 12, 0);

      provider.setSleepStartTime(startTime);
      expect(provider.sleepStartTime, startTime);
      expect(provider.isSleepOngoing, true);

      provider.setSleepEndTime(endTime);
      expect(provider.sleepEndTime, endTime);
      expect(provider.isSleepOngoing, false);
    });

    test('sleep duration calculation is correct', () {
      final startTime = DateTime(2026, 1, 30, 10, 0);
      final endTime = DateTime(2026, 1, 30, 12, 30);

      provider.setSleepStartTime(startTime);
      provider.setSleepEndTime(endTime);

      expect(provider.sleepDurationMinutes, 150);
    });
  });

  group('DiaperRecordProvider', () {
    late DiaperRecordProvider provider;

    setUp(() {
      provider = DiaperRecordProvider();
      provider.initialize(
        familyId: 'test-family',
        babies: testBabies,
      );
    });

    test('diaper type change works', () {
      expect(provider.diaperType, 'wet');
      provider.setDiaperType('dirty');
      expect(provider.diaperType, 'dirty');
      provider.setDiaperType('both');
      expect(provider.diaperType, 'both');
      provider.setDiaperType('dry');
      expect(provider.diaperType, 'dry');
    });

    test('stool color setting works', () {
      provider.setDiaperType('dirty');
      provider.setStoolColor('yellow');
      expect(provider.stoolColor, 'yellow');
    });

    test('wet/dry selection resets stool color', () {
      provider.setDiaperType('dirty');
      provider.setStoolColor('yellow');
      expect(provider.stoolColor, 'yellow');

      provider.setDiaperType('wet');
      expect(provider.stoolColor, null);
    });
  });

  group('PlayRecordProvider', () {
    late PlayRecordProvider provider;

    setUp(() {
      provider = PlayRecordProvider();
      provider.initialize(
        familyId: 'test-family',
        babies: testBabies,
      );
    });

    test('play type change works', () {
      expect(provider.playType, 'tummy_time');
      provider.setPlayType('bath');
      expect(provider.playType, 'bath');
      provider.setPlayType('outdoor');
      expect(provider.playType, 'outdoor');
      provider.setPlayType('play');
      expect(provider.playType, 'play');
      provider.setPlayType('reading');
      expect(provider.playType, 'reading');
    });

    test('play duration change works', () {
      expect(provider.playDuration, null);
      provider.setPlayDuration(15);
      expect(provider.playDuration, 15);
      provider.setPlayDuration(null);
      expect(provider.playDuration, null);
    });
  });

  group('HealthRecordProvider', () {
    late HealthRecordProvider provider;

    setUp(() {
      provider = HealthRecordProvider();
      provider.initialize(
        familyId: 'test-family',
        babies: testBabies,
      );
    });

    test('health type change works', () {
      expect(provider.healthType, 'temperature');
      provider.setHealthType('symptom');
      expect(provider.healthType, 'symptom');
      provider.setHealthType('medication');
      expect(provider.healthType, 'medication');
      provider.setHealthType('hospital');
      expect(provider.healthType, 'hospital');
    });

    test('temperature setting works', () {
      expect(provider.temperature, null);
      provider.setTemperature(36.5);
      expect(provider.temperature, 36.5);
      provider.setTemperature(38.2);
      expect(provider.temperature, 38.2);
    });

    test('symptom toggle works', () {
      expect(provider.symptoms.isEmpty, true);
      provider.toggleSymptom('fever');
      expect(provider.symptoms.contains('fever'), true);
      provider.toggleSymptom('cough');
      expect(provider.symptoms.length, 2);
      provider.toggleSymptom('fever');
      expect(provider.symptoms.contains('fever'), false);
      expect(provider.symptoms.length, 1);
    });

    test('medication setting works', () {
      expect(provider.medication, null);
      provider.setMedication('Tylenol 5ml');
      expect(provider.medication, 'Tylenol 5ml');
      provider.setMedication('  ');
      expect(provider.medication, null);
    });

    test('hospital visit setting works', () {
      expect(provider.hospitalVisit, null);
      provider.setHospitalVisit('Pediatric checkup');
      expect(provider.hospitalVisit, 'Pediatric checkup');
    });

    test('reset clears all state', () {
      provider.setHealthType('symptom');
      provider.setTemperature(37.5);
      provider.toggleSymptom('fever');

      provider.reset();

      expect(provider.familyId, null);
      expect(provider.babies.isEmpty, true);
      expect(provider.selectedBabyIds.isEmpty, true);
      expect(provider.healthType, 'temperature');
      expect(provider.temperature, null);
      expect(provider.symptoms.isEmpty, true);
    });
  });

  group('Shared functionality', () {
    test('empty babies means isSelectionValid is false', () {
      final provider = FeedingRecordProvider();
      provider.initialize(
        familyId: 'test-family',
        babies: [],
      );
      expect(provider.isSelectionValid, false);
    });

    test('babies present means isSelectionValid is true', () {
      final provider = FeedingRecordProvider();
      provider.initialize(
        familyId: 'test-family',
        babies: testBabies,
      );
      expect(provider.isSelectionValid, true);
    });
  });
}
