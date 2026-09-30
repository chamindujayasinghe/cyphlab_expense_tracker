import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

/// Auth state and actions for the UI. Actions return an error message,
/// or null on success.
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

  /// True until Firebase restores the saved login.
  bool get isInitializing => _isInitializing;

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
