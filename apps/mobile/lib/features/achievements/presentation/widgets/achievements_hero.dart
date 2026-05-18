import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/user_stats.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/earned_badges_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/user_gamification_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_icon.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

/// Top-of-screen hero block for [AchievementsScreen]. Surfaces the most
/// recently earned badge as a celebrated 96dp icon with name + earned-ago,
/// plus an "Up next" pointer to the closest still-locked badge.
///
/// Three states:
/// - **At least one earned** → recent badge hero + "Up next" line.
/// - **All earned** → most-prestigious badge hero + "You've earned them all".
/// - **None earned** → muted placeholder hero + a single-line prompt.
class AchievementsHero extends ConsumerWidget {
  const AchievementsHero({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog =
        ref.watch(badgeCatalogProvider).asData?.value ??
        const <AchievementBadge>[];
    final earned =
        ref.watch(earnedBadgesProvider(uid)).asData?.value ??
        const <EarnedBadge>[];
    // `userStatsProvider` reads `users/{uid}` directly, which Firestore
    // rules restrict to the owner. Other users' stats aren't available
    // here — the up-next nudge degrades gracefully when stats is null.
    final me = ref.watch(authStateProvider).asData?.value?.id;
    final isOwnProfile = me == uid;
    final stats = isOwnProfile
        ? ref.watch(userStatsProvider(uid)).asData?.value
        : null;

    if (catalog.isEmpty) {
      // Catalog still loading; render nothing rather than a flickering
      // placeholder.
      return const SizedBox.shrink();
    }

    final earnedById = <String, EarnedBadge>{
      for (final e in earned) e.badgeId: e,
    };
    final mostRecent = _mostRecent(earned);
    final mostRecentBadge = mostRecent != null
        ? _findBadge(catalog, mostRecent.badgeId)
        : null;
    final allEarned = earned.length == catalog.length;

    if (mostRecent == null || mostRecentBadge == null) {
      return _EmptyHero(stats: stats, catalog: catalog);
    }

    final upcoming = allEarned
        ? null
        : _closestLocked(catalog, stats, earnedById.keys.toSet());

    return _Hero(
      badge: mostRecentBadge,
      earned: mostRecent,
      upcoming: upcoming,
      stats: stats,
      allEarned: allEarned,
    );
  }

  static EarnedBadge? _mostRecent(List<EarnedBadge> earned) {
    if (earned.isEmpty) return null;
    // Stream is already ordered earnedAt-desc; defensive sort here keeps
    // the hero correct if a future caller passes an unsorted list.
    final sorted = [...earned]
      ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
    return sorted.first;
  }

  static AchievementBadge? _findBadge(
    List<AchievementBadge> catalog,
    String id,
  ) {
    for (final b in catalog) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Returns the locked badge the user is closest to unlocking, measured
  /// by fractional progress against its threshold. Falls back to the
  /// lowest-threshold locked badge when [stats] is unavailable.
  static _Upcoming? _closestLocked(
    List<AchievementBadge> catalog,
    UserStats? stats,
    Set<String> earnedIds,
  ) {
    final locked = catalog.where((b) => !earnedIds.contains(b.id)).toList();
    if (locked.isEmpty) return null;

    if (stats == null) {
      locked.sort(
        (a, b) => a.condition.threshold.compareTo(b.condition.threshold),
      );
      final b = locked.first;
      return _Upcoming(badge: b, current: 0, threshold: b.condition.threshold);
    }

    _Upcoming? best;
    double bestFraction = -1;
    for (final b in locked) {
      final current = stats.valueFor(b.condition.statKey);
      final threshold = b.condition.threshold;
      if (threshold <= 0) continue;
      final fraction = (current / threshold).clamp(0.0, 1.0);
      if (fraction > bestFraction) {
        bestFraction = fraction;
        best = _Upcoming(badge: b, current: current, threshold: threshold);
      }
    }
    return best;
  }
}

class _Upcoming {
  const _Upcoming({
    required this.badge,
    required this.current,
    required this.threshold,
  });
  final AchievementBadge badge;
  final int current;
  final int threshold;
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.badge,
    required this.earned,
    required this.upcoming,
    required this.stats,
    required this.allEarned,
  });
  final AchievementBadge badge;
  final EarnedBadge earned;
  final _Upcoming? upcoming;
  final UserStats? stats;
  final bool allEarned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Text(
            allEarned ? 'You\'ve earned them all' : 'Your latest unlock',
            style: AppTypography.mono(
              base: theme.textTheme.labelSmall?.copyWith(
                color: ac.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          BadgeIcon(badge: badge, locked: false, size: 96),
          const SizedBox(height: 12),
          Text(
            badge.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            allEarned
                ? 'Every badge in the v1 catalog. Nice work.'
                : 'Earned ${DateFormat.yMMMd().format(earned.earnedAt)} · +${earned.pointsAwarded} pts',
            style: theme.textTheme.bodySmall?.copyWith(color: ac.textSecondary),
          ),
          if (upcoming != null) ...[
            const SizedBox(height: 16),
            Divider(color: theme.dividerColor),
            const SizedBox(height: 12),
            _UpNext(upcoming: upcoming!),
          ],
        ],
      ),
    );
  }
}

class _UpNext extends StatelessWidget {
  const _UpNext({required this.upcoming});
  final _Upcoming upcoming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final remaining = (upcoming.threshold - upcoming.current).clamp(
      0,
      upcoming.threshold,
    );
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UP NEXT',
                style: AppTypography.mono(
                  base: theme.textTheme.labelSmall?.copyWith(
                    color: ac.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                upcoming.badge.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                remaining > 0
                    ? '$remaining to go · ${upcoming.current}/${upcoming.threshold}'
                    : 'Ready to unlock — wait for the trigger to fire',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ac.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        BadgeIcon(badge: upcoming.badge, locked: true, size: 48),
      ],
    );
  }
}

class _EmptyHero extends StatelessWidget {
  const _EmptyHero({required this.stats, required this.catalog});
  final UserStats? stats;
  final List<AchievementBadge> catalog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final cs = theme.colorScheme;

    final firstReach =
        catalog.where((b) => b.tier == BadgeTier.onboarding).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    final placeholderBadge = firstReach.isNotEmpty
        ? firstReach.first
        : catalog.first;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Text(
            'NO BADGES YET',
            style: AppTypography.mono(
              base: theme.textTheme.labelSmall?.copyWith(
                color: ac.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          BadgeIcon(badge: placeholderBadge, locked: true, size: 96),
          const SizedBox(height: 12),
          Text(
            'Your first achievement awaits',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Share a post, leave a comment, or save someone\'s work to start earning.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: ac.textSecondary),
          ),
        ],
      ),
    );
  }
}
