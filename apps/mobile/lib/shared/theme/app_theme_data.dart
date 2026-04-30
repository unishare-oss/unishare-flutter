import 'package:flutter/material.dart';

@immutable
class AppThemeData {
  const AppThemeData({
    required this.id,
    required this.name,
    required this.brightness,
    required this.background,
    required this.foreground,
    required this.card,
    required this.primary,
    required this.primaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.textSecondary,
    required this.textMuted,
    required this.amber,
    required this.amberHover,
    required this.amberSubtle,
    required this.success,
    required this.info,
    required this.surfaceDark,
    required this.cardDark,
  });

  final String id;
  final String name;
  final Brightness brightness;
  final Color background;
  final Color foreground;
  final Color card;
  final Color primary;
  final Color primaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color textSecondary;
  final Color textMuted;
  final Color amber;
  final Color amberHover;
  final Color amberSubtle;
  final Color success;
  final Color info;
  final Color surfaceDark;
  final Color cardDark;
}
