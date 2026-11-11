
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
 

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.light);
 
  static const _key = 'theme_mode';
 
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      value = ThemeMode.values.firstWhere(
        (mode) => mode.name == saved,
        orElse: () => ThemeMode.light,
      );
    } catch (_) {
      // Keep the default if storage is unavailable.
    }
  }
 
  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {
      // The change still applies for this session.
    }
  }
}
 
/// One shared instance for the whole app.
final themeController = ThemeController();
 

