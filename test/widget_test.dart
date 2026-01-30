import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:lulu_mvp_f/features/onboarding/presentation/screens/welcome_screen.dart';

void main() {
  testWidgets('WelcomeScreen displays correctly', (WidgetTester tester) async {
    // WelcomeScreen을 직접 테스트 (앱 전체 초기화 없이)
    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeScreen(),
      ),
    );

    // 여러 프레임 대기
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 환영 텍스트 확인
    expect(find.textContaining('환영해요'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
  });
}
