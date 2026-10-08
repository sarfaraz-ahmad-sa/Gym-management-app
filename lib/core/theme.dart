import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  bool dark = false;
  ThemeController() {
    _load();
  }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // Start the new appearance in light mode once, then honor future choices.
    if (prefs.getBool('fitguide.lightAppearanceV2') != true) {
      dark = false;
      await prefs.setBool('fitguide.dark', false);
      await prefs.setBool('fitguide.lightAppearanceV2', true);
    } else {
      dark = prefs.getBool('fitguide.dark') ?? false;
    }
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
  static const blue = Color(0xFF0068D9);
  static const green = Color(0xFF15803D);
  static const amber = Color(0xFFAD6508);
  static const red = Color(0xFFC24145);
  static ThemeData build(bool dark) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: blue,
          brightness: dark ? Brightness.dark : Brightness.light,
          surface: dark ? const Color(0xFF1C1C1E) : Colors.white,
        ).copyWith(
          primary: dark ? const Color(0xFF8EBFFF) : blue,
          onPrimary: dark ? const Color(0xFF002A5B) : Colors.white,
          primaryContainer: dark
              ? const Color(0xFF163355)
              : const Color(0xFFEAF2FF),
          onPrimaryContainer: dark
              ? const Color(0xFFD8E8FF)
              : const Color(0xFF164A89),
          onSurface: dark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
          onSurfaceVariant: dark
              ? const Color(0xFFB8B8C1)
              : const Color(0xFF636366),
          outline: dark ? const Color(0xFF66666D) : const Color(0xFF8E8E93),
          outlineVariant: dark
              ? const Color(0xFF3A3A3C)
              : const Color(0xFFE5E5EA),
          surfaceContainerHighest: dark
              ? const Color(0xFF2C2C2E)
              : const Color(0xFFF2F2F7),
        );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF000000)
          : const Color(0xFFF2F2F7),
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
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.4,
          color: scheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: scheme.onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: scheme.onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .35)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
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
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primaryContainer,
        height: 72,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 300),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
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
          dark ? const Color(0xFF2C2C2E) : const Color(0xFFF7F7FA),
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
