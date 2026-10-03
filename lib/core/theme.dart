import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  bool dark = false;
  ThemeController() {
    _load();
  }
  Future<void> _load() async {
    dark =
        (await SharedPreferences.getInstance()).getBool('fitguide.dark') ??
        false;
    notifyListeners();
  }

  Future<void> toggle() async {
    dark = !dark;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setBool(
      'fitguide.dark',
      dark,
    );
  }
}

class AppTheme {
  static const blue = Color(0xFF1A73E8);
  static const green = Color(0xFF188038);
  static const amber = Color(0xFFB06000);
  static const red = Color(0xFFD93025);
  static ThemeData build(bool dark) {
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: dark ? Brightness.dark : Brightness.light,
      surface: dark ? const Color(0xFF1B1D21) : Colors.white,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF111318)
          : const Color(0xFFF6F8FC),
      fontFamily: 'Roboto',
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
          color: scheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -.7,
          color: scheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          letterSpacing: -.3,
          color: scheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: scheme.onSurface),
        bodySmall: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .5)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF252830) : const Color(0xFFF8FAFD),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 19),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: .5),
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(
          dark ? const Color(0xFF252830) : const Color(0xFFF8FAFD),
        ),
        headingTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
        dataRowMinHeight: 70,
        dataRowMaxHeight: 78,
        horizontalMargin: 20,
        columnSpacing: 28,
      ),
    );
  }
}
