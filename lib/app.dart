import 'package:flutter/material.dart';

import 'screens/home/home_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

/// Root widget. Kept separate from `main.dart` so it can be pumped in widget
/// tests without initializing Firebase.
class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
