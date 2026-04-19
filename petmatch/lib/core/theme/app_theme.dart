import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary     = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color accent      = Color(0xFFFF6F00);
  static const Color background  = Color(0xFFF9FBF9);
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color error       = Color(0xFFB00020);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSec     = Color(0xFF757575);
  static const Color divider     = Color(0xFFBDBDBD);
  static const Color vetColor    = Color(0xFF6A1B9A);
  static const Color donColor    = Color(0xFF1565C0);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary, primary: primary,
      secondary: accent, surface: surface, error: error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primary, foregroundColor: Colors.white,
      elevation: 0, centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: error)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      elevation: 2, shadowColor: Colors.black12, color: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface, selectedItemColor: primary,
      unselectedItemColor: textSec, type: BottomNavigationBarType.fixed, elevation: 8,
    ),
    scaffoldBackgroundColor: background,
  );
}
