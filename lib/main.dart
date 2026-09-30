import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/expense_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Loaded up front so the saved theme applies from the first frame. If local
  // storage is unavailable the app still starts, using the system theme.
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {}

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(FirebaseAuthService()),
        ),
        // Follows the signed-in user: subscribes to their expenses on sign-in
        // and clears them on sign-out.
        ChangeNotifierProxyProvider<AuthProvider, ExpenseProvider>(
          create: (_) => ExpenseProvider(FirestoreExpenseRepository()),
          update: (_, auth, expenses) => expenses!..updateUser(auth.user?.uid),
        ),
      ],
      child: const ExpenseTrackerApp(),
    ),
  );
}
