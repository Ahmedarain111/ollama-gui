import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF0EA5E9);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme(colorScheme),
      inputDecorationTheme: _inputDecoration(colorScheme),
      cardTheme: _cardThemeLight(colorScheme),
      navigationRailTheme: _navRailTheme(colorScheme),
      dividerTheme: const DividerThemeData(space: 1, thickness: 1),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
    );
  }

  static ThemeData dark() {
    const background = Color(0xFF0F0F11);
    const surface = Color(0xFF1A1A1E);
    const surfaceVariant = Color(0xFF242428);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      surface: surface,
      onSurface: const Color(0xFFE2E8F0),
    ).copyWith(
      surfaceContainerHighest: surfaceVariant,
      surfaceContainerLow: background,
      surfaceContainer: surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: _textTheme(colorScheme),
      inputDecorationTheme: _inputDecoration(colorScheme),
      cardTheme: _cardThemeDark(colorScheme),
      navigationRailTheme: _navRailTheme(colorScheme),
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 1,
        color: Colors.white.withValues(alpha: 0.07),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        foregroundColor: colorScheme.onSurface,
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme colorScheme) {
    return GoogleFonts.interTextTheme().copyWith(
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.6,
        color: colorScheme.onSurface,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }

  static InputDecorationTheme _inputDecoration(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 1),
      ),
      hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4)),
    );
  }

  static CardThemeData _cardThemeLight(ColorScheme colorScheme) {
    return CardThemeData(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: colorScheme.surface,
    );
  }

  static CardThemeData _cardThemeDark(ColorScheme colorScheme) {
    return CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.07),
          width: 1,
        ),
      ),
      color: colorScheme.surfaceContainer,
    );
  }

  static NavigationRailThemeData _navRailTheme(ColorScheme colorScheme) {
    return NavigationRailThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      useIndicator: true,
      indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
      selectedIconTheme: IconThemeData(color: colorScheme.primary),
      unselectedIconTheme: IconThemeData(
        color: colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      labelType: NavigationRailLabelType.none,
    );
  }
}
