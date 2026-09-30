import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cyphlab_expense_tracker/models/expense.dart';
import 'package:cyphlab_expense_tracker/models/expense_category.dart';
import 'package:cyphlab_expense_tracker/providers/auth_provider.dart';
import 'package:cyphlab_expense_tracker/providers/expense_provider.dart';
import 'package:cyphlab_expense_tracker/providers/theme_provider.dart';
import 'package:cyphlab_expense_tracker/screens/auth/login_screen.dart';
import 'package:cyphlab_expense_tracker/screens/auth/register_screen.dart';
import 'package:cyphlab_expense_tracker/screens/expense_form/expense_form_screen.dart';
import 'package:cyphlab_expense_tracker/screens/main_shell.dart';
import 'package:cyphlab_expense_tracker/screens/settings/settings_screen.dart';
import 'package:cyphlab_expense_tracker/screens/summary/summary_screen.dart';
import 'package:cyphlab_expense_tracker/theme/app_theme.dart';

import '../fakes/fake_auth_service.dart';
import '../fakes/fake_expense_repository.dart';

/// Every screen on a 320x568 phone with 1.3x text, in both themes.
void main() {
  final expense = Expense(
    id: 'a',
    title: 'Weekly groceries at the supermarket near home',
    amount: 1234567.89,
    category: ExpenseCategory.entertainment,
    date: DateTime(2026, 9, 12),
    note: 'A fairly long note that should be truncated in the list tile',
  );

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    required ThemeMode themeMode,
  }) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = FakeExpenseRepository();
    final expenses = ExpenseProvider(
      repository,
      clock: () => DateTime(2026, 9, 29),
    )..updateUser('user-1');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider(null)),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(FakeAuthService()),
          ),
          ChangeNotifierProvider.value(value: expenses),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
    repository.emit([
      expense,
      expense.copyWith(id: 'b', category: ExpenseCategory.food, amount: 20),
    ]);
    await tester.pump(const Duration(milliseconds: 500));
  }

  final screens = <String, Widget>{
    'login': const LoginScreen(),
    'register': const RegisterScreen(),
    'expenses tab': const MainShell(),
    'add form': const ExpenseFormScreen(),
    'edit form': ExpenseFormScreen(expense: expense),
    'summary': const SummaryScreen(),
    'settings': const SettingsScreen(),
  };

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} fits a small screen (${mode.name})', (
        tester,
      ) async {
        // Overflow errors are reported by the framework and fail the test.
        await pumpScreen(tester, entry.value, themeMode: mode);
      });
    }
  }
}
