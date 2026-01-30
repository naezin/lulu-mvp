import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lulu_mvp_f/shared/widgets/quick_record_button.dart';
import 'package:lulu_mvp_f/data/models/activity_model.dart';
import 'package:lulu_mvp_f/data/models/baby_type.dart';

/// QuickRecordButton 위젯 테스트
///
/// Sprint 6 Day 9: v5.0 핵심 컴포넌트 검증
/// - "둘 다" 버튼 대체 UX
/// - 마지막 기록 기반 원탭 저장
void main() {
  late ActivityModel lastFeedingRecord;
  late ActivityModel lastSleepRecord;
  late ActivityModel lastDiaperRecord;

  setUp(() {
    lastFeedingRecord = ActivityModel(
      id: 'activity1',
      familyId: 'test-family',
      babyIds: ['baby1'],
      type: ActivityType.feeding,
      startTime: DateTime.now().subtract(const Duration(hours: 2)),
      data: {
        'feeding_type': 'formula',
        'amount_ml': 120,
      },
      createdAt: DateTime.now(),
    );

    lastSleepRecord = ActivityModel(
      id: 'activity2',
      familyId: 'test-family',
      babyIds: ['baby1'],
      type: ActivityType.sleep,
      startTime: DateTime.now().subtract(const Duration(hours: 3)),
      endTime: DateTime.now().subtract(const Duration(hours: 1)),
      data: {'sleep_type': 'nap'},
      createdAt: DateTime.now(),
    );

    lastDiaperRecord = ActivityModel(
      id: 'activity3',
      familyId: 'test-family',
      babyIds: ['baby1'],
      type: ActivityType.diaper,
      startTime: DateTime.now().subtract(const Duration(hours: 1)),
      data: {'diaper_type': 'wet'},
      createdAt: DateTime.now(),
    );
  });

  Widget buildTestWidget({
    ActivityModel? lastRecord,
    required ActivityType activityType,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: QuickRecordButton(
          lastRecord: lastRecord,
          activityType: activityType,
          onTap: onTap ?? () {},
          isLoading: isLoading,
        ),
      ),
    );
  }

  group('QuickRecordButton 렌더링 테스트', () {
    testWidgets('마지막 기록이 없으면 빈 위젯 반환', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        lastRecord: null,
        activityType: ActivityType.feeding,
      ));

      // SizedBox.shrink()이 반환됨
      expect(find.byType(QuickRecordButton), findsOneWidget);
      expect(find.text('이전과 같이'), findsNothing);
    });

    testWidgets('마지막 기록이 있으면 버튼 표시', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        lastRecord: lastFeedingRecord,
        activityType: ActivityType.feeding,
      ));

      expect(find.text('이전과 같이'), findsOneWidget);
      expect(find.text('원탭으로 저장'), findsOneWidget);
    });

    testWidgets('수유 기록 요약 표시', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        lastRecord: lastFeedingRecord,
        activityType: ActivityType.feeding,
      ));

      expect(find.text('분유 120ml'), findsOneWidget);
      expect(find.text('🍼'), findsOneWidget);
    });

    testWidgets('수면 기록 요약 표시', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        lastRecord: lastSleepRecord,
        activityType: ActivityType.sleep,
      ));

      expect(find.text('낮잠'), findsOneWidget);
      expect(find.text('😴'), findsOneWidget);
    });

    testWidgets('기저귀 기록 요약 표시', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        lastRecord: lastDiaperRecord,
        activityType: ActivityType.diaper,
      ));

      expect(find.text('소변'), findsOneWidget);
      expect(find.text('🧷'), findsOneWidget);
    });
  });

  group('QuickRecordButton 상호작용 테스트', () {
    testWidgets('탭 시 onTap 호출', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(buildTestWidget(
        lastRecord: lastFeedingRecord,
        activityType: ActivityType.feeding,
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(QuickRecordButton));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('로딩 중에는 탭 비활성화', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(buildTestWidget(
        lastRecord: lastFeedingRecord,
        activityType: ActivityType.feeding,
        onTap: () => tapped = true,
        isLoading: true,
      ));

      await tester.tap(find.byType(QuickRecordButton));
      // pumpAndSettle 대신 pump 사용 (애니메이션 무한 루프 방지)
      await tester.pump();

      expect(tapped, false);
    });

    testWidgets('로딩 중에는 프로그레스 표시', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        lastRecord: lastFeedingRecord,
        activityType: ActivityType.feeding,
        isLoading: true,
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('QuickRecordButton 다양한 활동 타입 테스트', () {
    testWidgets('놀이 기록 표시', (tester) async {
      final lastPlayRecord = ActivityModel(
        id: 'activity4',
        familyId: 'test-family',
        babyIds: ['baby1'],
        type: ActivityType.play,
        startTime: DateTime.now(),
        data: {
          'play_type': 'tummy_time',
          'duration_minutes': 15,
        },
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestWidget(
        lastRecord: lastPlayRecord,
        activityType: ActivityType.play,
      ));

      expect(find.text('터미타임 15분'), findsOneWidget);
      expect(find.text('🎮'), findsOneWidget);
    });

    testWidgets('건강 기록 (체온) 표시', (tester) async {
      final lastHealthRecord = ActivityModel(
        id: 'activity5',
        familyId: 'test-family',
        babyIds: ['baby1'],
        type: ActivityType.health,
        startTime: DateTime.now(),
        data: {
          'health_type': 'temperature',
          'temperature': 36.5,
        },
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestWidget(
        lastRecord: lastHealthRecord,
        activityType: ActivityType.health,
      ));

      expect(find.textContaining('36.5'), findsOneWidget);
      expect(find.text('🏥'), findsOneWidget);
    });
  });
}
