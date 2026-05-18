import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_icon.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class EarnMomentModal extends StatelessWidget {
  const EarnMomentModal({
    super.key,
    required this.badge,
    required this.points,
    this.levelUp,
  });
  final AchievementBadge badge;
  final int points;
  final int? levelUp;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: BadgeIcon(badge: badge, locked: false, size: 96)),
            const SizedBox(height: 16),
            Text(
              'Achievement unlocked',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(color: ac.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
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
              levelUp == null
                  ? '+$points pts'
                  : '+$points pts · Level up to Lv $levelUp',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: ac.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Nice'),
            ),
          ],
        ),
      ),
    );
  }
}
