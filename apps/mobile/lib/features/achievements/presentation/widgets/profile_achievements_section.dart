import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/earned_badges_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/level_progress_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/user_gamification_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_frame.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_icon.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/level_progress_bar.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class ProfileAchievementsSection extends ConsumerWidget {
  const ProfileAchievementsSection({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);

    final gamification = ref.watch(userGamificationProvider(uid)).asData?.value;
    final catalog = ref.watch(badgeCatalogProvider).asData?.value ?? const [];
    final progress = ref.watch(levelProgressProvider(uid));

    final displayedIds = gamification?.displayedBadges ?? const <String>[];
    final catalogById = <String, AchievementBadge>{
      for (final b in catalog) b.id: b,
    };
    final displayed = displayedIds
        .map((id) => catalogById[id])
        .whereType<AchievementBadge>()
        .toList(growable: false);

    return InkWell(
      onTap: () => context.push('/achievements/$uid'),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ACHIEVEMENTS',
                  style: AppTypography.mono(
                    base: theme.textTheme.labelSmall?.copyWith(
                      color: ac.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: ac.textMuted,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 14, color: ac.textMuted),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (displayed.isEmpty)
              _EmptyState(ac: ac)
            else
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: displayed
                    .map(
                      (b) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BadgeIcon(badge: b, locked: false),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 64,
                            child: Text(
                              b.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: ac.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 16),
            if (progress != null && gamification != null)
              LevelProgressBar(
                progress: progress,
                totalPoints: gamification.totalPoints,
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.ac});
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            return Padding(
              padding: EdgeInsets.only(right: i == 2 ? 0 : 12),
              child: const BadgeFrame(
                tier: BadgeTier.progression,
                locked: true,
                child: Icon(Icons.lock_outline),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Earn badges to display them here',
          style: theme.textTheme.labelSmall?.copyWith(color: ac.textMuted),
        ),
      ],
    );
  }
}
