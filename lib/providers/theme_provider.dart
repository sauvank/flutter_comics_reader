import 'dart:async';

import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';

enum AppThemeMode {
  dark,
  oled,
  light,
}

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.dark;
  late final StreamSubscription<void> _remoteSettingsSubscription;

  ThemeProvider() {
    _remoteSettingsSubscription =
        DatabaseService().remoteSettingsChanged.listen((_) => init());
  }

  AppThemeMode get mode => _mode;

  static const _languageKey = 'app_language';

  /// Language chosen in the settings (null = system language). Kept on this
  /// device only: each device may use its own language.
  String? get languageCode => userLocale?.languageCode;

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
    final savedLanguage = prefs.getString(_languageKey);
    if (savedLanguage != null &&
        languageNativeNames.containsKey(savedLanguage) &&
        userLocale?.languageCode != savedLanguage) {
      userLocale = Locale(savedLanguage);
      notifyListeners();
    }
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
    await DatabaseService().notifySettingsChanged();
  }

  Future<void> setLanguage(String? languageCode) async {
    userLocale = languageCode == null ? null : Locale(languageCode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (languageCode == null) {
      await prefs.remove(_languageKey);
    } else {
      await prefs.setString(_languageKey, languageCode);
    }
  }

  @override
  void dispose() {
    _remoteSettingsSubscription.cancel();
    super.dispose();
  }
}
