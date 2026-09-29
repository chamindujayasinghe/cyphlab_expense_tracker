import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cyphlab_expense_tracker/models/expense.dart';
import 'package:cyphlab_expense_tracker/models/expense_category.dart';
import 'package:cyphlab_expense_tracker/providers/auth_provider.dart';
import 'package:cyphlab_expense_tracker/providers/expense_provider.dart';
import 'package:cyphlab_expense_tracker/screens/home/home_screen.dart';
import 'package:cyphlab_expense_tracker/services/expense_repository.dart';
import 'package:cyphlab_expense_tracker/theme/app_theme.dart';

import '../fakes/fake_auth_service.dart';
import '../fakes/fake_expense_repository.dart';

void main() {
  late FakeExpenseRepository repository;
  late ExpenseProvider expenses;

  Future<void> pumpHome(
    WidgetTester tester, {
    DateTime Function()? clock,
  }) async {
    repository = FakeExpenseRepository();
    expenses = ExpenseProvider(repository, clock: clock)..updateUser('user-1');
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(FakeAuthService()),
          ),
          ChangeNotifierProvider.value(value: expenses),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );
  }

  DateTime fixedClock() => DateTime(2026, 9, 29, 10);

  testWidgets('shows a spinner while loading', (tester) async {
    await pumpHome(tester, clock: fixedClock);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('September 2026'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no expenses', (
    tester,
  ) async {
    await pumpHome(tester, clock: fixedClock);
    repository.emit([]);
    await tester.pump();

    expect(find.text('No expenses this month'), findsOneWidget);
    expect(find.text('LKR 0.00'), findsOneWidget);
  });

  testWidgets('lists expenses and shows the month total', (tester) async {
    await pumpHome(tester, clock: fixedClock);
    repository.emit([
      Expense(
        id: 'a',
        title: 'Lunch',
        amount: 1200,
        category: ExpenseCategory.food,
        date: DateTime(2026, 9, 12, 13),
      ),
      Expense(
        id: 'b',
        title: 'Bus fare',
        amount: 300,
        category: ExpenseCategory.transport,
        date: DateTime(2026, 9, 12, 8),
        note: 'To office',
      ),
    ]);
    await tester.pump();

    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Transport · To office'), findsOneWidget);
    expect(find.text('2 expenses'), findsOneWidget);
    // Month total in the card and the day total in the header.
    expect(find.text('LKR 1,500.00'), findsNWidgets(2));
  });

  testWidgets('shows the error state and retries', (tester) async {
    await pumpHome(tester, clock: fixedClock);
    repository.emitError(const ExpenseRepositoryException('Server down'));
    await tester.pump();

    expect(find.text('Could not load expenses'), findsOneWidget);
    expect(find.text('Server down'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();

    expect(repository.watchCount, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('add form validates, then saves and reports success', (
    tester,
  ) async {
    await pumpHome(tester);
    repository.emit([]);
    await tester.pump();

    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();

    // Submit empty form.
    await tester.tap(find.widgetWithText(FilledButton, 'Add expense'));
    await tester.pump();
    expect(find.text('Please enter a title'), findsOneWidget);
    expect(find.text('Please enter an amount'), findsOneWidget);
    expect(find.text('Please choose a category'), findsOneWidget);
    expect(repository.calls, isEmpty);

    await tester.enterText(find.byType(TextFormField).at(0), 'Groceries');
    await tester.enterText(find.byType(TextFormField).at(1), '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Add expense'));
    await tester.pump();
    expect(find.text('Amount must be greater than zero'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), '2,500.75');
    await tester.tap(find.text('Category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add expense'));
    await tester.pumpAndSettle();

    expect(repository.calls, ['add:user-1::Groceries']);
    expect(find.text('Expense added'), findsOneWidget);
  });
}
