import 'package:flutter/material.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class LevelChip extends StatelessWidget {
  const LevelChip({super.key, required this.level, this.onTap});
  final int level;

  /// When provided, the chip becomes tappable with a contained ink ripple
  /// matching the chip's rounded shape. Used on the profile card to open
  /// `/achievements/<uid>`.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ac.amberSubtle,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Lv $level',
        style: AppTypography.mono(
          base: theme.textTheme.labelSmall?.copyWith(
            color: ac.amber,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
    if (onTap == null) return chip;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: chip,
      ),
    );
  }
}
