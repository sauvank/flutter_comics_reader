import 'package:flutter/material.dart';

class AppTheme {
  // Dark Theme (Default)
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF8B5CF6), // Vibrant Purple
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF5B21B6),
      onPrimaryContainer: Color(0xFFDDD6FE),
      secondary: Color(0xFF06B6D4), // Cyan
      onSecondary: Colors.black,
      secondaryContainer: Color(0xFF164E63),
      onSecondaryContainer: Color(0xFFA5F3FC),
      tertiary: Color(0xFFF59E0B), // Amber for badges & bookmarks
      surface: Color(0xFF13151F),
      surfaceContainerHighest: Color(0xFF1E2235),
      surfaceContainer: Color(0xFF181B2A),
      onSurface: Color(0xFFF1F5F9),
      onSurfaceVariant: Color(0xFF94A3B8),
      error: Color(0xFFEF4444),
    ),
    scaffoldBackgroundColor: const Color(0xFF0B0D14),
    cardTheme: CardThemeData(
      color: const Color(0xFF181B2A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF232840), width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0B0D14),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF13151F),
      selectedItemColor: Color(0xFF8B5CF6),
      unselectedItemColor: Color(0xFF64748B),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF13151F),
      indicatorColor: const Color(0xFF8B5CF6).withAlpha(50),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8B5CF6),
          );
        }
        return const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.normal,
          color: Color(0xFF94A3B8),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Color(0xFF8B5CF6));
        }
        return const IconThemeData(color: Color(0xFF94A3B8));
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF181B2A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2B3250)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2B3250)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
      ),
      hintStyle: const TextStyle(color: Color(0xFF64748B)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF181B2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF8B5CF6),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  // OLED / Pure Black Theme
  static final ThemeData oledTheme = darkTheme.copyWith(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: darkTheme.colorScheme.copyWith(
      surface: const Color(0xFF0A0A0A),
      surfaceContainer: const Color(0xFF121212),
      surfaceContainerHighest: const Color(0xFF1A1A1A),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF121212),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF222222), width: 1),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: Color(0xFF8B5CF6),
      unselectedItemColor: Color(0xFF555555),
    ),
  );
}
