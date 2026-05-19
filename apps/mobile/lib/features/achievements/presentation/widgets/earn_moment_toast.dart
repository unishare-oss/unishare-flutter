import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_icon.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

SnackBar buildEarnMomentToast(
  BuildContext context,
  AchievementBadge badge,
  int points,
) {
  final ac = Theme.of(context).extension<AppColors>()!;
  final theme = Theme.of(context);
  return SnackBar(
    duration: const Duration(seconds: 3),
    backgroundColor: ac.surfaceDark,
    content: Row(
      children: [
        BadgeIcon(badge: badge, locked: false, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                badge.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.surface,
                ),
              ),
              Text(
                '+$points pts',
                style: theme.textTheme.labelSmall?.copyWith(color: ac.amber),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
