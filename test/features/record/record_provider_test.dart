import 'package:flutter_test/flutter_test.dart';
import 'package:lulu_mvp_f/features/record/providers/record_provider.dart';
import 'package:lulu_mvp_f/data/models/baby_model.dart';
import 'package:lulu_mvp_f/data/models/baby_type.dart';

/// RecordProvider 단위 테스트
///
/// Sprint 6 Day 9: 5종 기록 통합 테스트
void main() {
  late RecordProvider provider;
  late List<BabyModel> testBabies;

  setUp(() {
    provider = RecordProvider();

    // 테스트용 아기 데이터 (다태아 시나리오)
    testBabies = [
      BabyModel(
        id: 'baby1',
        familyId: 'test-family',
        name: '서준이',
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
        name: '서윤이',
        birthDate: DateTime.now().subtract(const Duration(days: 60)),
        gestationalWeeksAtBirth: 34,
        birthWeightGrams: 2100,
        multipleBirthType: BabyType.twin,
        birthOrder: 2,
        createdAt: DateTime.now(),
      ),
    ];
  });

  group('RecordProvider 초기화 테스트', () {
    test('초기화 시 기본값이 올바르게 설정됨', () {
      provider.initialize(
        familyId: 'test-family',
        babies: testBabies,
      );

      expect(provider.familyId, 'test-family');
      expect(provider.babies.length, 2);
      expect(provider.selectedBabyIds.length, 1);
      expect(provider.selectedBabyId, 'baby1');
      expect(provider.isSelectionValid, true);
    });

    test('preselectedBabyId가 있으면 해당 아기가 선택됨', () {
      provider.initialize(
        familyId: 'test-family',
        babies: testBabies,
        preselectedBabyId: 'baby2',
      );

      expect(provider.selectedBabyId, 'baby2');
    });

    test('아기 선택 변경이 동작함', () {
      provider.initialize(
        familyId: 'test-family',
        babies: testBabies,
      );

      provider.setSelectedBabyIds(['baby2']);

      expect(provider.selectedBabyId, 'baby2');
    });
  });

  group('수유 기록 테스트', () {
    setUp(() {
      provider.initialize(
        familyId: 'test-family',
        babies: testBabies,
      );
    });

    test('수유 종류 변경이 동작함', () {
      expect(provider.feedingType, 'breast'); // 기본값

      provider.setFeedingType('bottle');
      expect(provider.feedingType, 'bottle');

      provider.setFeedingType('formula');
      expect(provider.feedingType, 'formula');

      provider.setFeedingType('solid');
      expect(provider.feedingType, 'solid');
    });

    test('수유량 변경이 동작함', () {
      expect(provider.feedingAmount, 0);

      provider.setFeedingAmount(120);
      expect(provider.feedingAmount, 120);

      provider.setFeedingAmount(150);
      expect(provider.feedingAmount, 150);
    });

    test('모유 수유 좌/우 선택이 동작함', () {
      expect(provider.breastSide, 'left'); // 기본값

      provider.setBreastSide('right');
      expect(provider.breastSide, 'right');

      provider.setBreastSide('both');
      expect(provider.breastSide, 'both');
    });

    test('수유 시간 변경이 동작함', () {
      expect(provider.feedingDuration, 0);

      provider.setFeedingDuration(15);
      expect(provider.feedingDuration, 15);
    });
  });

  group('수면 기록 테스트', () {
    setUp(() {
      provider.initialize(
        familyId: 'test-family',
        babies: testBabies,
      );
    });

    test('수면 타입 변경이 동작함', () {
      expect(provider.sleepType, 'nap'); // 기본값

      provider.setSleepType('night');
      expect(provider.sleepType, 'night');
    });

    test('수면 시작/종료 시간 변경이 동작함', () {
      final startTime = DateTime(2026, 1, 30, 10, 0);
      final endTime = DateTime(2026, 1, 30, 12, 0);

      provider.setSleepStartTime(startTime);
      expect(provider.sleepStartTime, startTime);

      expect(provider.isSleepOngoing, true);

      provider.setSleepEndTime(endTime);
      expect(provider.sleepEndTime, endTime);
      expect(provider.isSleepOngoing, false);
    });

    test('수면 시간 계산이 올바름', () {
      final startTime = DateTime(2026, 1, 30, 10, 0);
      final endTime = DateTime(2026, 1, 30, 12, 30);

      provider.setSleepStartTime(startTime);
      provider.setSleepEndTime(endTime);

      expect(provider.sleepDurationMinutes, 150); // 2시간 30분 = 150분
    });
  });

  group('기저귀 기록 테스트', () {
    setUp(() {
      provider.initialize(
        familyId: 'test-family',
        babies: testBabies,
      );
    });

    test('기저귀 종류 변경이 동작함', () {
      expect(provider.diaperType, 'wet'); // 기본값

      provider.setDiaperType('dirty');
      expect(provider.diaperType, 'dirty');

      provider.setDiaperType('both');
      expect(provider.diaperType, 'both');

      provider.setDiaperType('dry');
      expect(provider.diaperType, 'dry');
    });

    test('대변 색상 설정이 동작함', () {
      provider.setDiaperType('dirty');
      provider.setStoolColor('yellow');

      expect(provider.stoolColor, 'yellow');
    });

    test('소변/건조 선택 시 색상이 초기화됨', () {
      provider.setDiaperType('dirty');
      provider.setStoolColor('yellow');
      expect(provider.stoolColor, 'yellow');

      provider.setDiaperType('wet');
      expect(provider.stoolColor, null);
    });
  });

  group('놀이 기록 테스트', () {
    setUp(() {
      provider.initialize(
        familyId: 'test-family',
        babies: testBabies,
      );
    });

    test('놀이 종류 변경이 동작함', () {
      expect(provider.playType, 'tummy_time'); // 기본값

      provider.setPlayType('bath');
      expect(provider.playType, 'bath');

      provider.setPlayType('outdoor');
      expect(provider.playType, 'outdoor');

      provider.setPlayType('play');
      expect(provider.playType, 'play');

      provider.setPlayType('reading');
      expect(provider.playType, 'reading');
    });

    test('놀이 시간 변경이 동작함', () {
      expect(provider.playDuration, null);

      provider.setPlayDuration(15);
      expect(provider.playDuration, 15);

      provider.setPlayDuration(null);
      expect(provider.playDuration, null);
    });
  });

  group('건강 기록 테스트', () {
    setUp(() {
      provider.initialize(
        familyId: 'test-family',
        babies: testBabies,
      );
    });

    test('건강 기록 종류 변경이 동작함', () {
      expect(provider.healthType, 'temperature'); // 기본값

      provider.setHealthType('symptom');
      expect(provider.healthType, 'symptom');

      provider.setHealthType('medication');
      expect(provider.healthType, 'medication');

      provider.setHealthType('hospital');
      expect(provider.healthType, 'hospital');
    });

    test('체온 설정이 동작함', () {
      expect(provider.temperature, null);

      provider.setTemperature(36.5);
      expect(provider.temperature, 36.5);

      provider.setTemperature(38.2);
      expect(provider.temperature, 38.2);
    });

    test('증상 토글이 동작함', () {
      expect(provider.symptoms.isEmpty, true);

      provider.toggleSymptom('fever');
      expect(provider.symptoms.contains('fever'), true);

      provider.toggleSymptom('cough');
      expect(provider.symptoms.length, 2);

      provider.toggleSymptom('fever');
      expect(provider.symptoms.contains('fever'), false);
      expect(provider.symptoms.length, 1);
    });

    test('투약 정보 설정이 동작함', () {
      expect(provider.medication, null);

      provider.setMedication('타이레놀 5ml');
      expect(provider.medication, '타이레놀 5ml');

      provider.setMedication('  ');
      expect(provider.medication, null);
    });

    test('병원 방문 정보 설정이 동작함', () {
      expect(provider.hospitalVisit, null);

      provider.setHospitalVisit('서울소아과 정기검진');
      expect(provider.hospitalVisit, '서울소아과 정기검진');
    });
  });

  group('공통 기능 테스트', () {
    setUp(() {
      provider.initialize(
        familyId: 'test-family',
        babies: testBabies,
      );
    });

    test('기록 시간 변경이 동작함', () {
      final newTime = DateTime(2026, 1, 30, 14, 30);

      provider.setRecordTime(newTime);
      expect(provider.recordTime, newTime);
    });

    test('메모 설정이 동작함', () {
      expect(provider.notes, null);

      provider.setNotes('테스트 메모');
      expect(provider.notes, '테스트 메모');

      provider.setNotes('  ');
      expect(provider.notes, null);
    });

    test('reset이 모든 상태를 초기화함', () {
      // 상태 변경
      provider.setFeedingType('bottle');
      provider.setFeedingAmount(120);
      provider.setDiaperType('dirty');
      provider.setPlayType('bath');
      provider.setTemperature(37.5);

      // 리셋
      provider.reset();

      // 검증
      expect(provider.familyId, null);
      expect(provider.babies.isEmpty, true);
      expect(provider.selectedBabyIds.isEmpty, true);
      expect(provider.feedingType, 'breast');
      expect(provider.feedingAmount, 0);
      expect(provider.diaperType, 'wet');
      expect(provider.playType, 'tummy_time');
      expect(provider.temperature, null);
    });
  });

  group('유효성 검사 테스트', () {
    test('아기가 선택되지 않으면 isSelectionValid가 false', () {
      provider.initialize(
        familyId: 'test-family',
        babies: [],
      );

      expect(provider.isSelectionValid, false);
    });

    test('아기가 선택되면 isSelectionValid가 true', () {
      provider.initialize(
        familyId: 'test-family',
        babies: testBabies,
      );

      expect(provider.isSelectionValid, true);
    });
  });
}
