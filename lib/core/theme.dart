import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Minimalist, modern design system for Ollama GUI.
/// Focuses on precision, typography, subtle hairlines, and restrained color.
class AppTheme {
  AppTheme._();

  // Dark Palette (Sophisticated Dark Slate / Zinc - softened black theme)
  static const Color darkBackground = Color(0xFF18191E);
  static const Color darkSurface = Color(0xFF202128);
  static const Color darkSurfaceRaised = Color(0xFF272932);
  static const Color darkBorder = Color(0xFF343642);
  static const Color darkBorderSubtle = Color(0xFF2B2D38);
  static const Color darkTextPrimary = Color(0xFFF4F4F7);
  static const Color darkTextSecondary = Color(0xFFA5A7B4);
  static const Color darkTextMuted = Color(0xFF787A87);

  // Light Palette (Alabaster / Paper)
  static const Color lightBackground = Color(0xFFFBFBFC);
  static const Color lightSurface = Color(0xFFF4F4F6);
  static const Color lightSurfaceRaised = Color(0xFFEBEBEF);
  static const Color lightBorder = Color(0xFFE4E4E7);
  static const Color lightBorderSubtle = Color(0xFFECECEF);
  static const Color lightTextPrimary = Color(0xFF18181B);
  static const Color lightTextSecondary = Color(0xFF52525B);
  static const Color lightTextMuted = Color(0xFFA1A1AA);

  // Accent (Restrained Indigo / Chalk)
  static const Color accentColor = Color(0xFF6366F1);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);

  static ThemeData dark() {
    final textTheme = _buildTextTheme(darkTextPrimary, darkTextSecondary, darkTextMuted);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        onPrimary: Colors.white,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        surfaceContainerLowest: darkBackground,
        surfaceContainerLow: darkSurface,
        surfaceContainer: darkSurface,
        surfaceContainerHigh: darkSurfaceRaised,
        surfaceContainerHighest: darkSurfaceRaised,
        outline: darkBorder,
        outlineVariant: darkBorderSubtle,
        onSurfaceVariant: darkTextSecondary,
        error: errorColor,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      tooltipTheme: TooltipThemeData(
        waitDuration: Duration.zero,
        showDuration: const Duration(seconds: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: darkSurfaceRaised,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: darkBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        textStyle: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        space: 1,
        thickness: 1,
        color: darkBorderSubtle,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceRaised,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentColor, width: 1.2),
        ),
        hintStyle: const TextStyle(
          color: darkTextMuted,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          elevation: const WidgetStatePropertyAll(0),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.12);
            }
            return null;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return darkSurfaceRaised;
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return darkSurfaceRaised;
            }
            return null;
          }),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return darkSurfaceRaised;
            }
            return null;
          }),
        ),
      ),
      segmentedButtonTheme: const SegmentedButtonThemeData(
        style: ButtonStyle(
          mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: darkSurface,
        useIndicator: true,
        indicatorColor: darkSurfaceRaised,
        selectedIconTheme: IconThemeData(color: darkTextPrimary, size: 20),
        unselectedIconTheme: IconThemeData(color: darkTextMuted, size: 20),
        labelType: NavigationRailLabelType.none,
      ),
    );
  }

  static ThemeData light() {
    final textTheme = _buildTextTheme(lightTextPrimary, lightTextSecondary, lightTextMuted);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: accentColor,
        onPrimary: Colors.white,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        surfaceContainerLowest: lightBackground,
        surfaceContainerLow: lightSurface,
        surfaceContainer: lightSurface,
        surfaceContainerHigh: lightSurfaceRaised,
        surfaceContainerHighest: lightSurfaceRaised,
        outline: lightBorder,
        outlineVariant: lightBorderSubtle,
        onSurfaceVariant: lightTextSecondary,
        error: errorColor,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      tooltipTheme: TooltipThemeData(
        waitDuration: Duration.zero,
        showDuration: const Duration(seconds: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: lightSurfaceRaised,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: lightBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        textStyle: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        space: 1,
        thickness: 1,
        color: lightBorderSubtle,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceRaised,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentColor, width: 1.2),
        ),
        hintStyle: const TextStyle(
          color: lightTextMuted,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          elevation: const WidgetStatePropertyAll(0),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.15);
            }
            return null;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return lightSurfaceRaised;
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return lightSurfaceRaised;
            }
            return null;
          }),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return lightSurfaceRaised;
            }
            return null;
          }),
        ),
      ),
      segmentedButtonTheme: const SegmentedButtonThemeData(
        style: ButtonStyle(
          mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: lightSurface,
        useIndicator: true,
        indicatorColor: lightSurfaceRaised,
        selectedIconTheme: IconThemeData(color: lightTextPrimary, size: 20),
        unselectedIconTheme: IconThemeData(color: lightTextMuted, size: 20),
        labelType: NavigationRailLabelType.none,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary, Color muted) {
    return GoogleFonts.interTextTheme().copyWith(
      headlineSmall: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.4,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.3,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primary,
        letterSpacing: -0.2,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
        height: 1.62,
        color: primary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        height: 1.58,
        color: primary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: secondary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        color: muted,
      ),
    );
  }
}
