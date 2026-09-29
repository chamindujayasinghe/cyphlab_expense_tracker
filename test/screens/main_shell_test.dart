import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cyphlab_expense_tracker/models/expense.dart';
import 'package:cyphlab_expense_tracker/models/expense_category.dart';
import 'package:cyphlab_expense_tracker/providers/auth_provider.dart';
import 'package:cyphlab_expense_tracker/providers/expense_provider.dart';
import 'package:cyphlab_expense_tracker/screens/main_shell.dart';
import 'package:cyphlab_expense_tracker/theme/app_theme.dart';

import '../fakes/fake_auth_service.dart';
import '../fakes/fake_expense_repository.dart';

void main() {
  late FakeExpenseRepository repository;
  late ExpenseProvider expenses;

  Future<void> pumpShell(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    repository = FakeExpenseRepository();
    expenses = ExpenseProvider(repository, clock: () => DateTime(2026, 9, 29))
      ..updateUser('user-1');
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(FakeAuthService()),
          ),
          ChangeNotifierProvider.value(value: expenses),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const MainShell()),
      ),
    );
    repository.emit([
      Expense(
        id: 'a',
        title: 'Lunch',
        amount: 1200,
        category: ExpenseCategory.food,
        date: DateTime(2026, 9, 12),
      ),
    ]);
    await tester.pump();
  }

  testWidgets('phone layout uses a labeled bottom navigation bar', (
    tester,
  ) async {
    await pumpShell(tester, const Size(420, 900));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Lunch'), findsOneWidget);

    await tester.tap(find.text('Summary'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Spending by category'), findsOneWidget);
    expect(find.text('Lunch'), findsNothing);
  });

  testWidgets('switching tabs keeps the search text', (tester) async {
    await pumpShell(tester, const Size(420, 900));

    await tester.enterText(find.byType(TextField).first, 'lun');
    await tester.tap(find.text('Summary'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Expenses'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('lun'), findsOneWidget);
    expect(expenses.searchQuery, 'lun');
  });

  testWidgets('wide layout uses a navigation rail', (tester) async {
    await pumpShell(tester, const Size(1200, 800));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('summary trend re-queries when the month changes', (
    tester,
  ) async {
    await pumpShell(tester, const Size(420, 900));
    await tester.tap(find.text('Summary'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(repository.lastWatch!.end, DateTime(2026, 10));

    expenses.previousMonth();
    await tester.pump();

    expect(repository.lastWatch!.start, DateTime(2026, 3));
    expect(repository.lastWatch!.end, DateTime(2026, 9));
  });
}
