import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../main_shell.dart';
import 'login_screen.dart';

/// Shows a splash while the persisted auth state loads, then the main tabs
/// for signed-in users or the login screen otherwise.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return auth.isSignedIn ? const MainShell() : const LoginScreen();
  }
}
