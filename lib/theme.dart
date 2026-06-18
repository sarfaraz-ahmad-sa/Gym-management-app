import 'package:flutter/material.dart';

/// Central theme for FitGuide. Dark, energetic, fitness-app feel.
class AppTheme {
  static const Color bg = Color(0xFF0E1116);
  static const Color surface = Color(0xFF171C24);
  static const Color surface2 = Color(0xFF1F2630);
  static const Color accent = Color(0xFFFF6B35); // energetic orange
  static const Color accent2 = Color(0xFF2EE6A6); // mint green (success)
  static const Color textMain = Color(0xFFF2F4F7);
  static const Color textDim = Color(0xFF9AA4B2);
  static const Color danger = Color(0xFFFF5A5F);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accent2,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textMain,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: textMain,
        displayColor: textMain,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
