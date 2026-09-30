import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's light/dark/system theme choice, persisted on the device.
///
/// Takes an already-loaded [SharedPreferences] so the saved choice is read
/// synchronously before the first frame (no flash of the wrong theme).
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
    // Losing the preference is harmless, so a failed write is ignored.
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
