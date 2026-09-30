import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light/dark/system theme choice, saved on the device.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._prefs) : _themeMode = _read(_prefs);

  static const _key = 'theme_mode';

  final SharedPreferences? _prefs;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    // A failed save is harmless, so it's ignored.
    try {
      await _prefs?.setString(_key, mode.name);
    } catch (_) {}
  }

  static ThemeMode _read(SharedPreferences? prefs) {
    final name = prefs?.getString(_key);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => ThemeMode.system,
    );
  }
}
