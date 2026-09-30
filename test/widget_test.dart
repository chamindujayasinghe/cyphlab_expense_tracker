import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cyphlab_expense_tracker/app.dart';
import 'package:cyphlab_expense_tracker/providers/auth_provider.dart';
import 'package:cyphlab_expense_tracker/providers/theme_provider.dart';

import 'fakes/fake_auth_service.dart';

void main() {
  late FakeAuthService service;

  Future<void> pumpApp(WidgetTester tester) async {
    service = FakeAuthService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider(null)),
          ChangeNotifierProvider(create: (_) => AuthProvider(service)),
        ],
        child: const ExpenseTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('signed-out user sees the login screen', (tester) async {
    await pumpApp(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
  });

  testWidgets('login validates fields before calling the service', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
    expect(service.calls, isEmpty);
  });

  testWidgets('login shows the service error in a snackbar', (tester) async {
    await pumpApp(tester);
    service.errorMessage = 'Incorrect email or password.';

    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(service.calls, ['signIn:a@b.com']);
    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets('register screen checks that passwords match', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret2');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(service.calls, isEmpty);
  });
}
