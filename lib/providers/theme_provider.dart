import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';

enum AppThemeMode {
  dark,
  oled,
  light,
}

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.dark;

  AppThemeMode get mode => _mode;

  ThemeData get currentTheme {
    switch (_mode) {
      case AppThemeMode.dark:
        return AppTheme.darkTheme;
      case AppThemeMode.oled:
        return AppTheme.oledTheme;
      case AppThemeMode.light:
        return ThemeData.light(useMaterial3: true).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B5CF6),
            brightness: Brightness.light,
          ),
        );
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('app_theme_mode');
    if (savedMode != null) {
      _mode = AppThemeMode.values.firstWhere(
        (e) => e.name == savedMode,
        orElse: () => AppThemeMode.dark,
      );
      notifyListeners();
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme_mode', mode.name);
  }
}
