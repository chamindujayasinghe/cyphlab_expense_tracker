import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cyphlab_expense_tracker/models/expense.dart';
import 'package:cyphlab_expense_tracker/models/expense_category.dart';
import 'package:cyphlab_expense_tracker/providers/expense_provider.dart';
import 'package:cyphlab_expense_tracker/screens/summary/summary_screen.dart';
import 'package:cyphlab_expense_tracker/theme/app_theme.dart';

import '../fakes/fake_expense_repository.dart';

void main() {
  late FakeExpenseRepository repository;
  late ExpenseProvider provider;

  final september = [
    Expense(
      id: 'a',
      title: 'Rent',
      amount: 3000,
      category: ExpenseCategory.bills,
      date: DateTime(2026, 9, 1),
    ),
    Expense(
      id: 'b',
      title: 'Lunch',
      amount: 1000,
      category: ExpenseCategory.food,
      date: DateTime(2026, 9, 12),
    ),
  ];

  Future<void> pumpSummary(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    repository = FakeExpenseRepository();
    provider = ExpenseProvider(repository, clock: () => DateTime(2026, 9, 29))
      ..updateUser('user-1');
    repository.emit(september);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(theme: AppTheme.light, home: const SummaryScreen()),
      ),
    );
  }

  test('watchMonthlyTotals queries the six months up to the selected one', () {
    final repo = FakeExpenseRepository();
    final p = ExpenseProvider(repo, clock: () => DateTime(2026, 3, 15))
      ..updateUser('user-1');

    p.watchMonthlyTotals().listen((_) {});

    expect(repo.lastWatch!.start, DateTime(2025, 10));
    expect(repo.lastWatch!.end, DateTime(2026, 4));
    p.dispose();
  });

  testWidgets('shows category totals and shares for the period', (
    tester,
  ) async {
    await pumpSummary(tester);
    await tester.pump();

    expect(find.text('Spending by category'), findsOneWidget);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('LKR 4,000.00'), findsOneWidget);
    expect(find.text('Bills'), findsOneWidget);
    expect(find.text('75%'), findsWidgets);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('25%'), findsWidgets);
  });

  testWidgets('trend chart loads from its own query', (tester) async {
    await pumpSummary(tester);
    await tester.pump();

    // The trend stream is the most recent watch; it is still loading.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.emit([
      ...september,
      Expense(
        id: 'c',
        title: 'Old',
        amount: 2000,
        category: ExpenseCategory.food,
        date: DateTime(2026, 7, 3),
      ),
    ]);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    // (4000 + 2000) / 6 months.
    expect(find.text('Average LKR 1,000.00 per month'), findsOneWidget);
  });

  testWidgets('shows empty states when there is no spending', (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repository = FakeExpenseRepository();
    provider = ExpenseProvider(repository)..updateUser('user-1');
    repository.emit([]);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(theme: AppTheme.light, home: const SummaryScreen()),
      ),
    );
    await tester.pump();
    repository.emit([]);
    await tester.pump();

    expect(find.text('Nothing to show yet'), findsOneWidget);
    expect(find.text('No spending yet'), findsOneWidget);
  });
}
