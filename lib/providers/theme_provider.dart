import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('tema');
    if (theme == 'claro') {
      _themeMode = ThemeMode.light;
    } else if (theme == 'escuro') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (themeMode == ThemeMode.light) {
      await prefs.setString('tema', 'claro');
    } else if (themeMode == ThemeMode.dark) {
      await prefs.setString('tema', 'escuro');
    } else {
      await prefs.remove('tema');
    }
  }
}
