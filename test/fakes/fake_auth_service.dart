import 'dart:async';

import 'package:cyphlab_expense_tracker/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// In-memory [AuthService] for tests. Starts signed out; set [errorMessage]
/// to make the next actions fail with an [AuthException].
class FakeAuthService implements AuthService {
  final _controller = StreamController<User?>.broadcast();

  String? errorMessage;
  final List<String> calls = [];

  /// Emits a signed-out state to listeners, as Firebase does on startup.
  void emitSignedOut() => _controller.add(null);

  @override
  Stream<User?> authStateChanges() {
    scheduleMicrotask(emitSignedOut);
    return _controller.stream;
  }

  @override
  User? get currentUser => null;

  @override
  Future<void> signIn({required String email, required String password}) =>
      _record('signIn:$email');

  @override
  Future<void> register({required String email, required String password}) =>
      _record('register:$email');

  @override
  Future<void> sendPasswordReset(String email) => _record('reset:$email');

  @override
  Future<void> signOut() => _record('signOut');

  Future<void> _record(String call) async {
    calls.add(call);
    final message = errorMessage;
    if (message != null) throw AuthException(message);
  }
}
