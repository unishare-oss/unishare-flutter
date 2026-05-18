import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

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
    final ac = Theme.of(context).extension<AppColors>()!;

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
          fill = ac.amber;
          glyphColor = ac.surfaceDark;
          break;
        case BadgeTier.progression:
          fill = ac.amberSubtle;
          glyphColor = ac.amber;
          border = Border.all(color: ac.amber, width: 1.5);
          break;
        case BadgeTier.prestige:
          fill = ac.surfaceDark;
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

    final radius = size * (8 / 48);
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
