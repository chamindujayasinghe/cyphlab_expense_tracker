import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

/// Exposes the signed-in user and auth actions to the UI.
///
/// Actions return an error message on failure, or null on success, so screens
/// can show feedback without handling exceptions themselves.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service) {
    _subscription = _service.authStateChanges().listen((user) {
      _user = user;
      _isInitializing = false;
      notifyListeners();
    });
  }

  final AuthService _service;
  late final StreamSubscription<User?> _subscription;

  User? _user;
  bool _isInitializing = true;
  bool _isSubmitting = false;
  bool _disposed = false;

  User? get user => _user;
  bool get isSignedIn => _user != null;

  /// True until Firebase reports the persisted auth state on startup.
  bool get isInitializing => _isInitializing;

  /// True while a sign-in, register, reset or sign-out request is running.
  bool get isSubmitting => _isSubmitting;

  Future<String?> signIn({required String email, required String password}) {
    return _run(() => _service.signIn(email: email, password: password));
  }

  Future<String?> register({required String email, required String password}) {
    return _run(() => _service.register(email: email, password: password));
  }

  Future<String?> sendPasswordReset(String email) {
    return _run(() => _service.sendPasswordReset(email));
  }

  Future<String?> signOut() => _run(_service.signOut);

  Future<String?> _run(Future<void> Function() action) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await action();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    } finally {
      _isSubmitting = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }
}
