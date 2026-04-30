import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_theme_data.dart';
import 'app_typography.dart';
import 'themes.dart';

class AppTheme {
  static ThemeData fromId(String id) =>
      build(AppThemes.all[id] ?? AppThemes.unishare);

  static ThemeData build(AppThemeData d) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: d.primary,
          brightness: d.brightness,
        ).copyWith(
          primary: d.primary,
          onPrimary: d.primaryForeground,
          secondary: d.accent,
          onSecondary: d.accentForeground,
          error: d.destructive,
          onError: d.destructiveForeground,
          surface: d.background,
          onSurface: d.foreground,
          outline: d.border,
          surfaceContainerHighest: d.card,
        );

    final appColors = AppColors(
      border: d.border,
      muted: d.muted,
      mutedForeground: d.mutedForeground,
      textSecondary: d.textSecondary,
      textMuted: d.textMuted,
      amber: d.amber,
      amberHover: d.amberHover,
      amberSubtle: d.amberSubtle,
      success: d.success,
      info: d.info,
      surfaceDark: d.surfaceDark,
      cardDark: d.cardDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: d.brightness,
      colorScheme: scheme,
      extensions: [appColors],
      textTheme: AppTypography.textTheme(d.foreground),
      scaffoldBackgroundColor: d.background,
      cardColor: d.card,
      dividerColor: d.border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: d.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: d.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: d.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: d.amber, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: d.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: d.border),
        ),
        elevation: 0,
      ),
    );
  }
}
