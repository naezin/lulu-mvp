import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lulu_mvp_f/shared/widgets/baby_tab_bar.dart';
import 'package:lulu_mvp_f/data/models/baby_model.dart';
import 'package:lulu_mvp_f/data/models/baby_type.dart';

/// BabyTabBar 위젯 테스트
///
/// Sprint 6 Day 9: v5.0 UX 검증
/// - "둘 다" 버튼이 제거되었는지 확인
/// - 탭 전환이 정상 동작하는지 확인
/// - 교정연령 표시가 올바른지 확인
void main() {
  late List<BabyModel> singleBaby;
  late List<BabyModel> twins;
  late List<BabyModel> triplets;

  setUp(() {
    // 단태아
    singleBaby = [
      BabyModel(
        id: 'baby1',
        familyId: 'test-family',
        name: '서준이',
        birthDate: DateTime.now().subtract(const Duration(days: 60)),
        gestationalWeeksAtBirth: 34,
        createdAt: DateTime.now(),
      ),
    ];

    // 쌍둥이
    twins = [
      BabyModel(
        id: 'baby1',
        familyId: 'test-family',
        name: '서준이',
        birthDate: DateTime.now().subtract(const Duration(days: 60)),
        gestationalWeeksAtBirth: 34,
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
        multipleBirthType: BabyType.twin,
        birthOrder: 2,
        createdAt: DateTime.now(),
      ),
    ];

    // 세쌍둥이
    triplets = [
      BabyModel(
        id: 'baby1',
        familyId: 'test-family',
        name: '서준이',
        birthDate: DateTime.now().subtract(const Duration(days: 60)),
        multipleBirthType: BabyType.triplet,
        birthOrder: 1,
        createdAt: DateTime.now(),
      ),
      BabyModel(
        id: 'baby2',
        familyId: 'test-family',
        name: '서윤이',
        birthDate: DateTime.now().subtract(const Duration(days: 60)),
        multipleBirthType: BabyType.triplet,
        birthOrder: 2,
        createdAt: DateTime.now(),
      ),
      BabyModel(
        id: 'baby3',
        familyId: 'test-family',
        name: '서연이',
        birthDate: DateTime.now().subtract(const Duration(days: 60)),
        multipleBirthType: BabyType.triplet,
        birthOrder: 3,
        createdAt: DateTime.now(),
      ),
    ];
  });

  Widget buildTestWidget({
    required List<BabyModel> babies,
    String? selectedBabyId,
    ValueChanged<String?>? onBabyChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BabyTabBar(
          babies: babies,
          selectedBabyId: selectedBabyId ?? babies.firstOrNull?.id,
          onBabyChanged: onBabyChanged ?? (_) {},
        ),
      ),
    );
  }

  group('BabyTabBar 렌더링 테스트', () {
    testWidgets('아기가 없으면 빈 위젯 반환', (tester) async {
      await tester.pumpWidget(buildTestWidget(babies: []));

      expect(find.byType(BabyTabBar), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('단태아면 탭 없이 교정연령만 표시 (조산아)', (tester) async {
      await tester.pumpWidget(buildTestWidget(babies: singleBaby));

      // 탭이 아닌 단순 헤더로 표시
      expect(find.text('서준이'), findsNothing); // 탭 형태가 아님
      expect(find.textContaining('교정'), findsOneWidget); // 교정연령 표시
    });

    testWidgets('쌍둥이면 두 개의 탭 표시', (tester) async {
      await tester.pumpWidget(buildTestWidget(babies: twins));

      expect(find.text('서준이'), findsOneWidget);
      expect(find.text('서윤이'), findsOneWidget);
    });

    testWidgets('세쌍둥이면 세 개의 탭 표시', (tester) async {
      await tester.pumpWidget(buildTestWidget(babies: triplets));

      expect(find.text('서준이'), findsOneWidget);
      expect(find.text('서윤이'), findsOneWidget);
      expect(find.text('서연이'), findsOneWidget);
    });

    testWidgets('"둘 다" 텍스트가 없음 (v5.0 핵심 검증)', (tester) async {
      await tester.pumpWidget(buildTestWidget(babies: twins));

      // "둘 다" 버튼이 제거되었는지 확인
      expect(find.text('둘 다'), findsNothing);
      expect(find.text('모두'), findsNothing);
      expect(find.text('전체'), findsNothing);
    });
  });

  group('BabyTabBar 상호작용 테스트', () {
    testWidgets('탭 클릭 시 onBabyChanged 호출', (tester) async {
      String? selectedId;

      await tester.pumpWidget(buildTestWidget(
        babies: twins,
        selectedBabyId: 'baby1',
        onBabyChanged: (id) => selectedId = id,
      ));

      // 두 번째 아기 탭 클릭
      await tester.tap(find.text('서윤이'));
      await tester.pumpAndSettle();

      expect(selectedId, 'baby2');
    });

    testWidgets('선택된 탭은 시각적으로 구분됨', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        babies: twins,
        selectedBabyId: 'baby1',
      ));

      // AnimatedContainer가 있으면 애니메이션 적용됨
      expect(find.byType(AnimatedContainer), findsWidgets);
    });
  });

  group('BabyTabBar 교정연령 표시 테스트', () {
    testWidgets('조산아 쌍둥이는 각 탭에 교정연령 표시', (tester) async {
      await tester.pumpWidget(buildTestWidget(babies: twins));

      // 교정연령 텍스트 존재 (정확한 값은 현재 날짜에 따라 다름)
      expect(find.textContaining('교정'), findsWidgets);
    });

    testWidgets('만삭아는 교정연령 표시 없음', (tester) async {
      final fullTermBabies = [
        BabyModel(
          id: 'baby1',
          familyId: 'test-family',
          name: '만삭이',
          birthDate: DateTime.now().subtract(const Duration(days: 60)),
          // gestationalWeeksAtBirth 없음 = 만삭
          multipleBirthType: BabyType.twin,
          birthOrder: 1,
          createdAt: DateTime.now(),
        ),
        BabyModel(
          id: 'baby2',
          familyId: 'test-family',
          name: '건강이',
          birthDate: DateTime.now().subtract(const Duration(days: 60)),
          multipleBirthType: BabyType.twin,
          birthOrder: 2,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(babies: fullTermBabies));

      // 교정연령 텍스트 없음
      expect(find.textContaining('교정'), findsNothing);
    });
  });
}
