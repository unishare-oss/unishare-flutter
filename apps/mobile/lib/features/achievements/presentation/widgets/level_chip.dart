import 'package:flutter/material.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class LevelChip extends StatelessWidget {
  const LevelChip({super.key, required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    return Container(
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
  }
}
