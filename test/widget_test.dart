import 'package:flutter_test/flutter_test.dart';

import 'package:expense_manager_app/app.dart';

void main() {
  testWidgets('Expense app renders navigation tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExpenseManagerApp());

    expect(find.text('Chi tiêu'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
