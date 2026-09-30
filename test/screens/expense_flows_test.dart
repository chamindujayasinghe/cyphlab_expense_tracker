import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cyphlab_expense_tracker/models/expense.dart';
import 'package:cyphlab_expense_tracker/models/expense_category.dart';
import 'package:cyphlab_expense_tracker/providers/expense_provider.dart';
import 'package:cyphlab_expense_tracker/screens/home/home_screen.dart';
import 'package:cyphlab_expense_tracker/theme/app_theme.dart';

import '../fakes/fake_expense_repository.dart';

/// End-to-end UI flows on the Expenses screen: edit, delete with undo,
/// swipe to delete, and the unsaved-changes guard.
void main() {
  late FakeExpenseRepository repository;

  final lunch = Expense(
    id: 'a',
    title: 'Lunch',
    amount: 1200,
    category: ExpenseCategory.food,
    date: DateTime(2026, 9, 12, 13),
    note: 'Team',
  );

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    repository = FakeExpenseRepository();
    final provider = ExpenseProvider(
      repository,
      clock: () => DateTime(2026, 9, 29),
    )..updateUser('user-1');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );
    repository.emit([lunch]);
    await tester.pump();
  }

  testWidgets(
    'tapping an expense opens a prefilled edit form that updates it',
    (tester) async {
      await pumpHome(tester);

      await tester.tap(find.text('Lunch'));
      await tester.pumpAndSettle();

      expect(find.text('Edit expense'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Lunch'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '1200'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Team'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Lunch'),
        'Brunch',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
      await tester.pumpAndSettle();

      expect(repository.calls, ['update:user-1:a']);
      expect(find.text('Expense updated'), findsOneWidget);
    },
  );

  testWidgets('deleting from the edit form removes it and offers undo', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.text('Lunch'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete expense'));
    await tester.pumpAndSettle();
    expect(find.text('Delete expense?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repository.calls, ['delete:user-1:a']);
    expect(find.text('"Lunch" deleted'), findsOneWidget);
    // Removed from the list straight away, before Firestore confirms.
    expect(find.widgetWithText(ListTile, 'Lunch'), findsNothing);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(repository.calls, ['delete:user-1:a', 'add:user-1:a:Lunch']);
  });

  testWidgets('swiping asks for confirmation; cancel keeps the expense', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.drag(find.text('Lunch'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Delete expense?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.calls, isEmpty);
    expect(find.text('Lunch'), findsOneWidget);

    await tester.drag(find.text('Lunch'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repository.calls, ['delete:user-1:a']);
    expect(find.text('"Lunch" deleted'), findsOneWidget);
  });

  testWidgets('leaving a form with unsaved changes asks to discard', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();

    // No changes yet: back closes straight away.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Add expense'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);

    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Coffee');
    // Let the form rebuild and register the unsaved change, as it would
    // between a real keystroke and tap.
    await tester.pump();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Coffee'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Discard'));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNothing);
    expect(repository.calls, isEmpty);
  });
}
