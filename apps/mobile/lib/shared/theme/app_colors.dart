import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.border,
    required this.muted,
    required this.mutedForeground,
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

  final Color border;
  final Color muted;
  final Color mutedForeground;
  final Color textSecondary;
  final Color textMuted;
  final Color amber;
  final Color amberHover;
  final Color amberSubtle;
  final Color success;
  final Color info;
  final Color surfaceDark;
  final Color cardDark;

  @override
  AppColors copyWith({
    Color? border,
    Color? muted,
    Color? mutedForeground,
    Color? textSecondary,
    Color? textMuted,
    Color? amber,
    Color? amberHover,
    Color? amberSubtle,
    Color? success,
    Color? info,
    Color? surfaceDark,
    Color? cardDark,
  }) {
    return AppColors(
      border: border ?? this.border,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      amber: amber ?? this.amber,
      amberHover: amberHover ?? this.amberHover,
      amberSubtle: amberSubtle ?? this.amberSubtle,
      success: success ?? this.success,
      info: info ?? this.info,
      surfaceDark: surfaceDark ?? this.surfaceDark,
      cardDark: cardDark ?? this.cardDark,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberHover: Color.lerp(amberHover, other.amberHover, t)!,
      amberSubtle: Color.lerp(amberSubtle, other.amberSubtle, t)!,
      success: Color.lerp(success, other.success, t)!,
      info: Color.lerp(info, other.info, t)!,
      surfaceDark: Color.lerp(surfaceDark, other.surfaceDark, t)!,
      cardDark: Color.lerp(cardDark, other.cardDark, t)!,
    );
  }
}
