import 'package:flutter_test/flutter_test.dart';

import 'package:cyphlab_expense_tracker/providers/auth_provider.dart';
import 'package:cyphlab_expense_tracker/services/auth_service.dart';

import '../fakes/fake_auth_service.dart';

void main() {
  late FakeAuthService service;
  late AuthProvider provider;

  setUp(() {
    service = FakeAuthService();
    provider = AuthProvider(service);
  });

  tearDown(() => provider.dispose());

  test('is initializing until the first auth state arrives', () async {
    expect(provider.isInitializing, isTrue);

    await pumpEventQueue();

    expect(provider.isInitializing, isFalse);
    expect(provider.isSignedIn, isFalse);
  });

  test('signIn returns null on success and toggles isSubmitting', () async {
    final states = <bool>[];
    provider.addListener(() => states.add(provider.isSubmitting));

    final error = await provider.signIn(email: 'a@b.com', password: 'secret1');

    expect(error, isNull);
    expect(service.calls, ['signIn:a@b.com']);
    expect(states, containsAllInOrder([true, false]));
    expect(provider.isSubmitting, isFalse);
  });

  test('actions return the service error message on failure', () async {
    service.errorMessage = 'Incorrect email or password.';

    final error = await provider.register(email: 'a@b.com', password: 'x');

    expect(error, 'Incorrect email or password.');
    expect(provider.isSubmitting, isFalse);
  });

  test('messageForCode maps known codes and falls back', () {
    expect(
      FirebaseAuthService.messageForCode('invalid-credential'),
      'Incorrect email or password.',
    );
    expect(
      FirebaseAuthService.messageForCode('email-already-in-use'),
      'An account already exists with this email.',
    );
    expect(
      FirebaseAuthService.messageForCode('some-new-code'),
      'Something went wrong. Please try again.',
    );
  });
}
