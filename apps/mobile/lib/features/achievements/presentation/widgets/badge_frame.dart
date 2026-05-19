import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

/// Corner radius for a badge frame of the given pixel [size]. Exposed so
/// callers can pass a matching [BorderRadius] to `InkWell.borderRadius`
/// and keep tap ripples clipped to the frame.
double badgeFrameRadius(double size) => size * (8 / 48);

/// Tier-aware frame for an achievement badge. Pure decoration — composed
/// with a glyph in [BadgeIcon]. All colors come from the app theme via
/// [AppColors] / [ColorScheme].
///
/// - onboarding (earned): solid amber fill, dark glyph
/// - progression (earned): subtle amber fill with amber border + glyph
/// - prestige (earned): dark surface with a thin amber accent bar on top
/// - locked (any tier): muted fill, muted glyph
class BadgeFrame extends StatelessWidget {
  const BadgeFrame({
    super.key,
    required this.tier,
    required this.locked,
    required this.child,
    this.size = 48,
  });

  final BadgeTier tier;
  final bool locked;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ac = theme.extension<AppColors>()!;
    final isDark = theme.brightness == Brightness.dark;

    final Color fill;
    final Color glyphColor;
    Border? border;
    Widget? accent;

    if (locked) {
      fill = ac.muted;
      glyphColor = ac.textMuted;
    } else {
      switch (tier) {
        case BadgeTier.onboarding:
          // `cs.onPrimary` is the theme-provided contrast for the primary
          // (amber) color — gives clean white-on-amber across both
          // brightnesses, instead of muddy near-black-on-amber that some
          // light themes produced via `ac.surfaceDark`.
          fill = ac.amber;
          glyphColor = cs.onPrimary;
          break;
        case BadgeTier.progression:
          fill = ac.amberSubtle;
          glyphColor = ac.amber;
          border = Border.all(color: ac.amber, width: 1.5);
          break;
        case BadgeTier.prestige:
          // `ac.surfaceDark` is reliably dark only in dark themes; some
          // light themes define it as a mid-gray which makes the prestige
          // medal look washed-out. Fall back to `cs.onSurface` in light
          // themes — that's the high-contrast foreground (near-black) and
          // gives a striking medal look.
          fill = isDark ? ac.surfaceDark : cs.onSurface;
          glyphColor = ac.amber;
          accent = Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 2, color: ac.amber),
          );
          break;
      }
    }

    final radius = badgeFrameRadius(size);
    return Container(
      key: const Key('badge_frame_container'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: border,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ?accent,
          IconTheme.merge(
            data: IconThemeData(color: glyphColor, size: size * (24 / 48)),
            child: child,
          ),
        ],
      ),
    );
  }
}
