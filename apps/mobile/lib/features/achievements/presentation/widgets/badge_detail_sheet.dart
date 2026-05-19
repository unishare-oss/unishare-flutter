import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_icon.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class BadgeDetailSheet extends StatelessWidget {
  const BadgeDetailSheet({super.key, required this.badge, this.earned});
  final AchievementBadge badge;
  final EarnedBadge? earned;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final isEarned = earned != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BadgeIcon(badge: badge, locked: !isEarned, size: 96),
            const SizedBox(height: 16),
            Text(badge.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ac.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEarned
                  ? 'Earned ${DateFormat.yMMMd().format(earned!.earnedAt)} · +${earned!.pointsAwarded} pts'
                  : '+${badge.points} pts when unlocked',
              style: theme.textTheme.labelSmall?.copyWith(color: ac.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
