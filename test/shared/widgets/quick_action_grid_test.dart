import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lulu_mvp_f/shared/widgets/quick_action_grid.dart';

/// QuickActionGrid 위젯 테스트
///
/// Sprint 6 Day 9: 5종 기록 버튼 그리드 검증
void main() {
  Widget buildTestWidget({
    VoidCallback? onFeedingTap,
    VoidCallback? onSleepTap,
    VoidCallback? onDiaperTap,
    VoidCallback? onPlayTap,
    VoidCallback? onHealthTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: QuickActionGrid(
          onFeedingTap: onFeedingTap,
          onSleepTap: onSleepTap,
          onDiaperTap: onDiaperTap,
          onPlayTap: onPlayTap,
          onHealthTap: onHealthTap,
        ),
      ),
    );
  }

  group('QuickActionGrid 렌더링 테스트', () {
    testWidgets('5종 기록 버튼이 모두 표시됨', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // 5종 기록 라벨
      expect(find.text('수유'), findsOneWidget);
      expect(find.text('수면'), findsOneWidget);
      expect(find.text('기저귀'), findsOneWidget);
      expect(find.text('놀이'), findsOneWidget);
      expect(find.text('건강'), findsOneWidget);
    });

    testWidgets('5종 기록 이모지가 표시됨', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('🍼'), findsOneWidget);
      expect(find.text('😴'), findsOneWidget);
      expect(find.text('🧷'), findsOneWidget);
      expect(find.text('🎮'), findsOneWidget);
      expect(find.text('🏥'), findsOneWidget);
    });

    testWidgets('빠른 기록 헤더 표시', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('빠른 기록'), findsOneWidget);
    });
  });

  group('QuickActionGrid 상호작용 테스트', () {
    testWidgets('수유 버튼 탭 시 onFeedingTap 호출', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(buildTestWidget(
        onFeedingTap: () => tapped = true,
      ));

      await tester.tap(find.text('수유'));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('수면 버튼 탭 시 onSleepTap 호출', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(buildTestWidget(
        onSleepTap: () => tapped = true,
      ));

      await tester.tap(find.text('수면'));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('기저귀 버튼 탭 시 onDiaperTap 호출', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(buildTestWidget(
        onDiaperTap: () => tapped = true,
      ));

      await tester.tap(find.text('기저귀'));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('놀이 버튼 탭 시 onPlayTap 호출', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(buildTestWidget(
        onPlayTap: () => tapped = true,
      ));

      await tester.tap(find.text('놀이'));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('건강 버튼 탭 시 onHealthTap 호출', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(buildTestWidget(
        onHealthTap: () => tapped = true,
      ));

      await tester.tap(find.text('건강'));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });
  });

  group('QuickActionGrid 터치 피드백 테스트', () {
    testWidgets('버튼에 AnimatedBuilder가 있음 (터치 피드백)', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // AnimatedBuilder가 터치 피드백을 위해 사용됨
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('GestureDetector가 모든 버튼에 적용됨', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // 5개 버튼 각각에 GestureDetector 적용
      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}
