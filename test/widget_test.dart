import 'package:flutter_test/flutter_test.dart';

import 'package:cyphlab_expense_tracker/app.dart';

void main() {
  testWidgets('App launches to the home screen', (tester) async {
    await tester.pumpWidget(const ExpenseTrackerApp());

    expect(find.text('Expense Tracker'), findsOneWidget);
    expect(find.text('Your expenses will appear here'), findsOneWidget);
  });
}
