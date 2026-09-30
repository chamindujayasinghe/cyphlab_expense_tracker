import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cyphlab_expense_tracker/providers/theme_provider.dart';

void main() {
  test('defaults to system when nothing is saved', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    expect(ThemeProvider(prefs).themeMode, ThemeMode.system);
  });

  test('reads the saved mode on startup', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    final prefs = await SharedPreferences.getInstance();

    expect(ThemeProvider(prefs).themeMode, ThemeMode.dark);
  });

  test('ignores an unknown saved value', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'sepia'});
    final prefs = await SharedPreferences.getInstance();

    expect(ThemeProvider(prefs).themeMode, ThemeMode.system);
  });

  test('setThemeMode notifies and persists across restarts', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final provider = ThemeProvider(prefs);
    var notified = 0;
    provider.addListener(() => notified++);

    await provider.setThemeMode(ThemeMode.light);

    expect(provider.themeMode, ThemeMode.light);
    expect(notified, 1);
    expect(ThemeProvider(prefs).themeMode, ThemeMode.light);
  });

  test('works without storage', () async {
    final provider = ThemeProvider(null);

    await provider.setThemeMode(ThemeMode.dark);

    expect(provider.themeMode, ThemeMode.dark);
  });
}
