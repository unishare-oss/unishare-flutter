import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/level_tier.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class LevelProgressBar extends StatelessWidget {
  const LevelProgressBar({
    super.key,
    required this.progress,
    required this.totalPoints,
  });
  final LevelProgress progress;
  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final fraction = progress.fractionToNext.clamp(0.0, 1.0);
    final ceiling = totalPoints + progress.pointsToNextLevel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: ac.muted,
            valueColor: AlwaysStoppedAnimation(ac.amber),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$totalPoints / $ceiling pts to Lv ${progress.currentLevel + 1}',
          style: AppTypography.mono(
            base: theme.textTheme.labelSmall?.copyWith(
              color: ac.textMuted,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}
