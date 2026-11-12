import 'package:flutter/material.dart';

/// Semantic colors for the Ollama GUI design system.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.bgSidebar,
    required this.surface,
    required this.surfaceHover,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.accentHover,
    required this.accentTextOn,
    required this.codeBg,
    required this.success,
    required this.warning,
    required this.error,
  });

  final Color bg;
  final Color bgSidebar;
  final Color surface;
  final Color surfaceHover;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color accentHover;
  final Color accentTextOn;
  final Color codeBg;
  final Color success;
  final Color warning;
  final Color error;

  static const AppColors dark = AppColors(
    bg: Color(0xFF0F1115),
    bgSidebar: Color(0xFF14171C),
    surface: Color(0xFF1A1E25),
    surfaceHover: Color(0xFF212630),
    border: Color(0xFF2A2F38),
    text: Color(0xFFE6E8EB),
    textMuted: Color(0xFF8B93A1),
    accent: Color(0xFF7C83FF),
    accentHover: Color(0xFF9197FF),
    accentTextOn: Color(0xFF0F1115),
    codeBg: Color(0xFF0B0D10),
    success: Color(0xFF3DDC97),
    warning: Color(0xFFF5B84B),
    error: Color(0xFFF0616D),
  );

  static const AppColors light = AppColors(
    bg: Color(0xFFFAFAFB),
    bgSidebar: Color(0xFFF2F3F6),
    surface: Color(0xFFFFFFFF),
    surfaceHover: Color(0xFFF0F2F5),
    border: Color(0xFFE3E6EB),
    text: Color(0xFF16181D),
    textMuted: Color(0xFF5F6877),
    accent: Color(0xFF5B63F0),
    accentHover: Color(0xFF4A52E0),
    accentTextOn: Color(0xFFFFFFFF),
    codeBg: Color(0xFFF3F4F7),
    success: Color(0xFF14A06A),
    warning: Color(0xFFC98A12),
    error: Color(0xFFD63F4C),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? bgSidebar,
    Color? surface,
    Color? surfaceHover,
    Color? border,
    Color? text,
    Color? textMuted,
    Color? accent,
    Color? accentHover,
    Color? accentTextOn,
    Color? codeBg,
    Color? success,
    Color? warning,
    Color? error,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      bgSidebar: bgSidebar ?? this.bgSidebar,
      surface: surface ?? this.surface,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      border: border ?? this.border,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      accentTextOn: accentTextOn ?? this.accentTextOn,
      codeBg: codeBg ?? this.codeBg,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      bgSidebar: Color.lerp(bgSidebar, other.bgSidebar, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      accentTextOn: Color.lerp(accentTextOn, other.accentTextOn, t)!,
      codeBg: Color.lerp(codeBg, other.codeBg, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

/// 4px grid spacing tokens.
class AppSpacing {
  AppSpacing._();
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

/// Standardized corner radii:
/// - 6px: chips, tags, small controls
/// - 8px: buttons, inputs, dropdowns
/// - 12px: cards, dialogs, composer, code blocks
class AppRadius {
  AppRadius._();
  static const double k6 = 6.0;
  static const double k8 = 8.0;
  static const double k12 = 12.0;

  static const double chip = 6.0;
  static const double button = 8.0;
  static const double input = 8.0;
  static const double card = 12.0;
  static const double dialog = 12.0;

  static final BorderRadius r6 = BorderRadius.circular(k6);
  static final BorderRadius r8 = BorderRadius.circular(k8);
  static final BorderRadius r12 = BorderRadius.circular(k12);

  static final BorderRadius chipRadius = r6;
  static final BorderRadius buttonRadius = r8;
  static final BorderRadius inputRadius = r8;
  static final BorderRadius cardRadius = r12;
}

/// Motion transitions:
/// - 150ms ease-out for hover / focus
/// - 200ms ease-out for panels and dialogs
class AppMotion {
  AppMotion._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration panel = Duration(milliseconds: 200);
  static const Curve curve = Curves.easeOut;

  static const Duration shortDuration = Duration(milliseconds: 150);
  static const Duration panelDuration = Duration(milliseconds: 200);
  static const Curve standardCurve = Curves.easeOut;
}

/// Strict typography scale and font families.
class AppTypography {
  AppTypography._();

  static const String uiFontFamily = 'Inter';
  static const String codeFontFamily = 'JetBrainsMono';

  static const List<String> uiFallbacks = [
    'Inter',
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  static const List<String> codeFallbacks = [
    'JetBrainsMono',
    'JetBrains Mono',
    'Fira Code',
    'Consolas',
    'monospace',
  ];

  static const String uiFont = uiFontFamily;
  static const String codeFont = codeFontFamily;

  static TextStyle ui({
    required double size,
    Color? color,
    FontWeight? weight,
    FontWeight? fontWeight,
    double height = 1.4,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: uiFontFamily,
      fontFamilyFallback: uiFallbacks,
      fontSize: size,
      fontWeight: fontWeight ?? weight ?? FontWeight.w400,
      height: height,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle code({
    required double size,
    Color? color,
    FontWeight? weight,
    FontWeight? fontWeight,
    double height = 1.4,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: codeFontFamily,
      fontFamilyFallback: codeFallbacks,
      fontSize: size,
      fontWeight: fontWeight ?? weight ?? FontWeight.w400,
      height: height,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle caption({
    double size = 12,
    Color? color,
    FontWeight? weight,
    FontWeight? fontWeight,
  }) =>
      ui(size: size, color: color, weight: fontWeight ?? weight ?? FontWeight.w400);

  static TextStyle secondary({
    double size = 13,
    Color? color,
    FontWeight? weight,
    FontWeight? fontWeight,
  }) =>
      ui(size: size, color: color, weight: fontWeight ?? weight ?? FontWeight.w400);

  static TextStyle body({
    double size = 14,
    Color? color,
    FontWeight? weight,
    FontWeight? fontWeight,
  }) =>
      ui(size: size, color: color, weight: fontWeight ?? weight ?? FontWeight.w400);

  static TextStyle chatBody({
    double size = 15,
    Color? color,
    FontWeight? weight,
    FontWeight? fontWeight,
  }) =>
      ui(size: size, color: color, weight: fontWeight ?? weight ?? FontWeight.w400, height: 1.6);

  static TextStyle section({
    double size = 18,
    Color? color,
    FontWeight? weight,
    FontWeight? fontWeight,
  }) =>
      ui(size: size, color: color, weight: fontWeight ?? weight ?? FontWeight.w600);

  static TextStyle title({
    double size = 22,
    Color? color,
    FontWeight? weight,
    FontWeight? fontWeight,
  }) =>
      ui(size: size, color: color, weight: fontWeight ?? weight ?? FontWeight.w600);

  static TextStyle button({
    double size = 13,
    Color? color,
    FontWeight? weight,
    FontWeight? fontWeight,
  }) =>
      ui(size: size, color: color, weight: fontWeight ?? weight ?? FontWeight.w500);
}

/// Central Theme definition for Ollama GUI.
class AppTheme {
  AppTheme._();

  // Backward compatible static references redirecting to design system tokens
  static const Color darkBackground = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF1A1E25);
  static const Color darkSurfaceRaised = Color(0xFF212630);
  static const Color darkBorder = Color(0xFF2A2F38);
  static const Color darkBorderSubtle = Color(0xFF2A2F38);
  static const Color darkTextPrimary = Color(0xFFE6E8EB);
  static const Color darkTextSecondary = Color(0xFF8B93A1);
  static const Color darkTextMuted = Color(0xFF8B93A1);

  static const Color lightBackground = Color(0xFFFAFAFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceRaised = Color(0xFFF0F2F5);
  static const Color lightBorder = Color(0xFFE3E6EB);
  static const Color lightBorderSubtle = Color(0xFFE3E6EB);
  static const Color lightTextPrimary = Color(0xFF16181D);
  static const Color lightTextSecondary = Color(0xFF5F6877);
  static const Color lightTextMuted = Color(0xFF5F6877);

  static const Color accentColor = Color(0xFF7C83FF);
  static const Color successColor = Color(0xFF3DDC97);
  static const Color errorColor = Color(0xFFF0616D);

  static AppColors colors(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ??
        (Theme.of(context).brightness == Brightness.dark ? AppColors.dark : AppColors.light);
  }

  static ThemeData dark([Color? accent, Color? accentHover]) {
    final base = AppColors.dark;
    final colors = accent != null
        ? base.copyWith(
            accent: accent,
            accentHover: accentHover ?? accent,
          )
        : base;
    return _buildTheme(colors, Brightness.dark);
  }

  static ThemeData light([Color? accent, Color? accentHover]) {
    final base = AppColors.light;
    final colors = accent != null
        ? base.copyWith(
            accent: accent,
            accentHover: accentHover ?? accent,
          )
        : base;
    return _buildTheme(colors, Brightness.light);
  }

  static ThemeData _buildTheme(AppColors colors, Brightness brightness) {
    final textTheme = _buildTextTheme(colors.text, colors.textMuted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.bg,
      extensions: [colors],
      colorScheme: (brightness == Brightness.dark
              ? const ColorScheme.dark()
              : const ColorScheme.light())
          .copyWith(
            primary: colors.accent,
            onPrimary: colors.accentTextOn,
            surface: colors.surface,
            onSurface: colors.text,
            surfaceContainerLowest: colors.bg,
            surfaceContainerLow: colors.bgSidebar,
            surfaceContainer: colors.surface,
            surfaceContainerHigh: colors.surfaceHover,
            surfaceContainerHighest: colors.surfaceHover,
            outline: colors.border,
            outlineVariant: colors.border,
            onSurfaceVariant: colors.textMuted,
            error: colors.error,
            onError: colors.accentTextOn,
          ),
      textTheme: textTheme,
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 250),
        showDuration: const Duration(seconds: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.r6,
          border: Border.all(color: colors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: brightness == Brightness.dark ? 0.35 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        textStyle: AppTypography.ui(
          size: 12,
          color: colors.text,
          weight: FontWeight.w400,
        ),
      ),
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 1,
        color: colors.border,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        foregroundColor: colors.text,
        centerTitle: false,
        titleTextStyle: AppTypography.ui(
          size: 14,
          weight: FontWeight.w600,
          color: colors.text,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.r12,
          side: BorderSide(color: colors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: AppRadius.r8,
          borderSide: BorderSide(color: colors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.r8,
          borderSide: BorderSide(color: colors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.r8,
          borderSide: BorderSide(color: colors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.r8,
          borderSide: BorderSide(color: colors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.r8,
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.r8,
          borderSide: BorderSide(color: colors.border.withValues(alpha: 0.5), width: 1),
        ),
        hintStyle: AppTypography.ui(
          size: 13,
          color: colors.textMuted,
          weight: FontWeight.w400,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          elevation: const WidgetStatePropertyAll(0),
          minimumSize: const WidgetStatePropertyAll(Size(32, 32)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.border.withValues(alpha: 0.4);
            }
            if (states.contains(WidgetState.hovered)) {
              return colors.accentHover;
            }
            return colors.accent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.textMuted;
            }
            return colors.accentTextOn;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.r8),
          ),
          textStyle: WidgetStatePropertyAll(
            AppTypography.ui(size: 13, weight: FontWeight.w500),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          minimumSize: const WidgetStatePropertyAll(Size(32, 32)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.textMuted;
            }
            if (states.contains(WidgetState.hovered)) {
              return colors.text;
            }
            return colors.textMuted;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return colors.surfaceHover;
            }
            return null;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.r8),
          ),
          textStyle: WidgetStatePropertyAll(
            AppTypography.ui(size: 13, weight: FontWeight.w500),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          minimumSize: const WidgetStatePropertyAll(Size(32, 32)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return BorderSide(color: colors.accent, width: 2);
            }
            return BorderSide(color: colors.border, width: 1);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return colors.textMuted;
            return colors.text;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return colors.surfaceHover;
            }
            return null;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.r8),
          ),
          textStyle: WidgetStatePropertyAll(
            AppTypography.ui(size: 13, weight: FontWeight.w500),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          minimumSize: const WidgetStatePropertyAll(Size(32, 32)),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return colors.textMuted;
            if (states.contains(WidgetState.hovered)) return colors.text;
            return colors.textMuted;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return colors.surfaceHover;
            }
            return null;
          }),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: brightness == Brightness.dark ? 0.5 : 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.r12,
          side: BorderSide(color: colors.border, width: 1),
        ),
        titleTextStyle: AppTypography.ui(
          size: 18,
          weight: FontWeight.w600,
          color: colors.text,
        ),
        contentTextStyle: AppTypography.ui(
          size: 13,
          color: colors.textMuted,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surface,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: brightness == Brightness.dark ? 0.5 : 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.r12,
          side: BorderSide(color: colors.border, width: 1),
        ),
        textStyle: AppTypography.ui(
          size: 13,
          color: colors.text,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.r6),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: colors.border, width: 1),
          ),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(false),
        trackVisibility: const WidgetStatePropertyAll(false),
        thickness: const WidgetStatePropertyAll(4),
        radius: const Radius.circular(2),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return colors.textMuted.withValues(alpha: 0.6);
          }
          return colors.border;
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.bgSidebar,
        useIndicator: true,
        indicatorColor: colors.surfaceHover,
        selectedIconTheme: IconThemeData(color: colors.accent, size: 20),
        unselectedIconTheme: IconThemeData(color: colors.textMuted, size: 20),
        labelType: NavigationRailLabelType.none,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color muted) {
    return TextTheme(
      headlineMedium: AppTypography.ui(
        size: 22,
        weight: FontWeight.w600,
        color: primary,
      ),
      headlineSmall: AppTypography.ui(
        size: 18,
        weight: FontWeight.w600,
        color: primary,
      ),
      titleLarge: AppTypography.ui(
        size: 18,
        weight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: AppTypography.ui(
        size: 14,
        weight: FontWeight.w500,
        color: primary,
      ),
      titleSmall: AppTypography.ui(
        size: 13,
        weight: FontWeight.w500,
        color: primary,
      ),
      bodyLarge: AppTypography.ui(
        size: 15,
        weight: FontWeight.w400,
        height: 1.6,
        color: primary,
      ),
      bodyMedium: AppTypography.ui(
        size: 14,
        weight: FontWeight.w400,
        height: 1.4,
        color: primary,
      ),
      bodySmall: AppTypography.ui(
        size: 12,
        weight: FontWeight.w400,
        height: 1.4,
        color: muted,
      ),
      labelMedium: AppTypography.ui(
        size: 13,
        weight: FontWeight.w500,
        color: primary,
      ),
      labelSmall: AppTypography.code(
        size: 12,
        weight: FontWeight.w400,
        color: muted,
      ),
    );
  }
}

extension ThemeX on BuildContext {
  AppColors get appColors => AppTheme.colors(this);
}
