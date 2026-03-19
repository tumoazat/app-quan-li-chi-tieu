import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appchitieu/features/onboarding/presentation/onboarding_screen.dart';
import 'package:appchitieu/features/onboarding/presentation/widgets/onboarding_page.dart';

void main() {
  group('OnboardingScreen', () {
    testWidgets('renders three onboarding pages', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
      await tester.pump();

      // The PageView should be present
      expect(find.byType(PageView), findsOneWidget);

      // First page content should be visible
      expect(find.byType(OnboardingPage), findsWidgets);
    });

    testWidgets('skip button is visible on first page', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Bỏ qua'), findsOneWidget);
    });

    testWidgets('next button is visible on first page', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Tiếp theo'), findsOneWidget);
    });

    testWidgets('last page shows Bắt đầu instead of Tiếp theo',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
      await tester.pump();

      // Swipe to last page
      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();

      expect(find.text('Bắt đầu'), findsOneWidget);
    });
  });
}
