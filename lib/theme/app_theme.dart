import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() => _buildTheme(_lightScheme, Brightness.light);

  static ThemeData dark() => _buildTheme(_darkScheme, Brightness.dark);

  static ThemeData _buildTheme(
    ColorScheme colorScheme,
    Brightness brightness,
  ) {
    final textTheme = _textTheme(brightness);
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle:
            textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: isDark ? _DarkColors.surface1 : _LightColors.surface1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? _DarkColors.chipBg : _LightColors.chipBg,
        selectedColor: colorScheme.primary.withValues(alpha: 0.16),
        disabledColor: colorScheme.surfaceContainerHighest,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? _DarkColors.surface1 : _LightColors.surface1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(48),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline),
          minimumSize: const Size.fromHeight(48),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final base = GoogleFonts.interTextTheme();
    final primaryColor = brightness == Brightness.dark
        ? _DarkColors.textPrimary
        : _LightColors.textPrimary;

    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontSize: 34,
            height: 40 / 34,
            fontWeight: FontWeight.w600,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontSize: 28,
            height: 34 / 28,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontSize: 22,
            height: 28 / 22,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w500,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w500,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w500,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w500,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w500,
          ),
        )
        .apply(
          bodyColor: primaryColor,
          displayColor: primaryColor,
        );
  }
}

class _BaseColors {
  static const primary = Color(0xFF5590A8);
  static const secondary = Color(0xFF4682B4);
  static const hover = Color(0xFF4C8AA1);
  static const success = Color(0xFF1F9D62);
  static const warning = Color(0xFFC77800);
  static const danger = Color(0xFFD7322D);
  static const info = Color(0xFF2F62CC);
}

class _DarkColors {
  static const surface = Color(0xFF121212);
  static const surface1 = Color(0xFF161A1E);
  static const surface2 = Color(0xFF1C2127);
  static const textPrimary = Color(0xFFE9EEF5);
  static const textSecondary = Color(0xFFB7C1CF);
  static const textTertiary = Color(0xFF8A95A6);
  static const lineSoft = Color(0xFF2A3038);
  static const lineStrong = Color(0xFF3A414B);
  static const chipBg = Color(0xFF20262D);
}

class _LightColors {
  static const surface = Color(0xFFF6F8FB);
  static const surface1 = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFEEF2F7);
  static const textPrimary = Color(0xFF1B2430);
  static const textSecondary = Color(0xFF445065);
  static const textTertiary = Color(0xFF63718A);
  static const textInverse = Color(0xFFFFFFFF);
  static const lineSoft = Color(0xFFD7DEE8);
  static const lineStrong = Color(0xFFC2CBD8);
  static const chipBg = Color(0xFFE9EFF7);
}

extension AppSemanticColors on ThemeData {
  Color get success => _BaseColors.success;

  Color get warning => _BaseColors.warning;

  Color get info => _BaseColors.info;

  Color get lineSoft => brightness == Brightness.dark
      ? _DarkColors.lineSoft
      : _LightColors.lineSoft;

  Color get lineStrong => brightness == Brightness.dark
      ? _DarkColors.lineStrong
      : _LightColors.lineStrong;

  Color get chipBackground =>
      brightness == Brightness.dark ? _DarkColors.chipBg : _LightColors.chipBg;

  Color get textSecondary => brightness == Brightness.dark
      ? _DarkColors.textSecondary
      : _LightColors.textSecondary;

  Color get textTertiary => brightness == Brightness.dark
      ? _DarkColors.textTertiary
      : _LightColors.textTertiary;
}

const ColorScheme _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: _BaseColors.primary,
  onPrimary: Colors.white,
  primaryContainer: _BaseColors.hover,
  onPrimaryContainer: Colors.white,
  secondary: _BaseColors.secondary,
  onSecondary: Colors.white,
  secondaryContainer: _DarkColors.surface2,
  onSecondaryContainer: _DarkColors.textPrimary,
  tertiary: _BaseColors.info,
  onTertiary: Colors.white,
  tertiaryContainer: _DarkColors.surface2,
  onTertiaryContainer: _DarkColors.textPrimary,
  error: _BaseColors.danger,
  onError: Colors.white,
  errorContainer: _BaseColors.danger,
  onErrorContainer: Colors.white,
  // ignore: deprecated_member_use
  background: _DarkColors.surface,
  // ignore: deprecated_member_use
  onBackground: _DarkColors.textPrimary,
  surface: _DarkColors.surface1,
  onSurface: _DarkColors.textPrimary,
  // ignore: deprecated_member_use
  surfaceVariant: _DarkColors.surface2,
  onSurfaceVariant: _DarkColors.textSecondary,
  outline: _DarkColors.lineSoft,
  outlineVariant: _DarkColors.lineStrong,
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: _LightColors.surface1,
  inversePrimary: _BaseColors.primary,
  surfaceTint: _BaseColors.primary,
);

const ColorScheme _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: _BaseColors.primary,
  onPrimary: _LightColors.textInverse,
  primaryContainer: _BaseColors.hover,
  onPrimaryContainer: _LightColors.textInverse,
  secondary: _BaseColors.secondary,
  onSecondary: _LightColors.textInverse,
  secondaryContainer: _LightColors.surface2,
  onSecondaryContainer: _LightColors.textPrimary,
  tertiary: _BaseColors.info,
  onTertiary: _LightColors.textInverse,
  tertiaryContainer: _LightColors.surface2,
  onTertiaryContainer: _LightColors.textPrimary,
  error: _BaseColors.danger,
  onError: _LightColors.textInverse,
  errorContainer: _BaseColors.danger,
  onErrorContainer: _LightColors.textInverse,
  // ignore: deprecated_member_use
  background: _LightColors.surface,
  // ignore: deprecated_member_use
  onBackground: _LightColors.textPrimary,
  surface: _LightColors.surface1,
  onSurface: _LightColors.textPrimary,
  // ignore: deprecated_member_use
  surfaceVariant: _LightColors.surface2,
  onSurfaceVariant: _LightColors.textSecondary,
  outline: _LightColors.lineSoft,
  outlineVariant: _LightColors.lineStrong,
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: _DarkColors.surface1,
  inversePrimary: _BaseColors.primary,
  surfaceTint: _BaseColors.primary,
);
