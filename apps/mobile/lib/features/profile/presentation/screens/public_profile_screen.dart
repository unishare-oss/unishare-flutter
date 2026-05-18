import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/public_user.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/public_user_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_icon.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/level_chip.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/title_chip.dart';
import 'package:unishare_mobile/features/feed/presentation/widgets/post_card.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/presentation/providers/posts_by_author_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';
import 'package:unishare_mobile/shared/widgets/main_nav_bar.dart';

/// Read-only profile view for any uid other than the signed-in user.
/// Reads exclusively from `users_public/{uid}` via [publicUserProvider]
/// — the owner-only `users/{uid}` doc is never touched here, so this
/// screen works for cross-user navigation (PostCard author taps, future
/// leaderboards, notification deep-links).
class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final pu = ref.watch(publicUserProvider(uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: pu.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _CenteredMessage(
          icon: Icons.error_outline,
          text: 'Could not load profile.',
          ac: ac,
        ),
        data: (user) {
          if (user == null) {
            return _CenteredMessage(
              icon: Icons.person_off_outlined,
              text: 'Profile not available.',
              ac: ac,
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MainNavBar.bottomInset + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PublicProfileCard(user: user),
                const SizedBox(height: 24),
                _PublicPostsSection(uid: user.uid, name: user.name),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PublicProfileCard extends ConsumerWidget {
  const _PublicProfileCard({required this.user});
  final PublicUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(photoUrl: user.photoUrl, name: user.name, ac: ac),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        LevelChip(
                          level: user.level,
                          onTap: () =>
                              context.push('/achievements/${user.uid}'),
                        ),
                      ],
                    ),
                    if (user.selectedTitle != null) ...[
                      const SizedBox(height: 2),
                      _SelectedTitle(badgeId: user.selectedTitle!),
                    ],
                    if (user.bio != null) ...[
                      const SizedBox(height: 8),
                      Text(user.bio!, style: theme.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 12),
          _DisplayedBadges(badgeIds: user.displayedBadges, uid: user.uid),
        ],
      ),
    );
  }
}

class _SelectedTitle extends ConsumerWidget {
  const _SelectedTitle({required this.badgeId});
  final String badgeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve id -> human-readable badge name via the catalog. Same
    // fallback pattern as ProfileCard so the chip never disappears while
    // the catalog is still loading.
    final catalog =
        ref.watch(badgeCatalogProvider).asData?.value ?? const [];
    final match = catalog
        .where((b) => b.id == badgeId)
        .cast<AchievementBadge?>()
        .firstWhere((_) => true, orElse: () => null);
    return TitleChip(title: match?.name ?? badgeId);
  }
}

class _DisplayedBadges extends ConsumerWidget {
  const _DisplayedBadges({required this.badgeIds, required this.uid});
  final List<String> badgeIds;
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final catalog =
        ref.watch(badgeCatalogProvider).asData?.value ?? const [];
    final byId = {for (final b in catalog) b.id: b};
    final displayed = badgeIds
        .map((id) => byId[id])
        .whereType<AchievementBadge>()
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACHIEVEMENTS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: ac.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            InkWell(
              onTap: () => context.push('/achievements/$uid'),
              borderRadius: BorderRadius.circular(4),
              child: Row(
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
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (displayed.isEmpty)
          Text(
            'No badges displayed yet.',
            style: theme.textTheme.labelSmall?.copyWith(color: ac.textMuted),
          )
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
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.photoUrl,
    required this.name,
    required this.ac,
  });
  final String? photoUrl;
  final String name;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          placeholder: (_, _) => _fallback(context),
          errorWidget: (_, _, _) => _fallback(context),
        ),
      );
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context) => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: ac.muted,
      borderRadius: BorderRadius.circular(6),
    ),
    alignment: Alignment.center,
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        color: ac.textMuted,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/// Renders the author's public posts (anonymous posts filtered out)
/// below the achievements card. Uses `ListView.builder(shrinkWrap: true,
/// primary: false)` so it nests inside the outer SingleChildScrollView
/// without owning its own scroll position.
class _PublicPostsSection extends ConsumerWidget {
  const _PublicPostsSection({required this.uid, required this.name});
  final String uid;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final async = ref.watch(postsByAuthorProvider(uid));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'POSTS BY ${name.toUpperCase()}',
          style: AppTypography.mono(
            base: theme.textTheme.labelSmall?.copyWith(
              color: ac.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Could not load posts.',
              style: theme.textTheme.bodySmall?.copyWith(color: ac.textMuted),
            ),
          ),
          data: (all) {
            final visible = all
                .where((p) => p.postingIdentity != PostingIdentity.anonymous)
                .toList(growable: false);
            if (visible.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No public posts yet.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ac.textMuted,
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visible.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: theme.dividerColor),
              itemBuilder: (_, i) => PostCard(
                post: visible[i],
                // We're already on this user's profile — re-tapping their
                // name would just push another /profile/:uid on the stack.
                suppressAuthorTapForUid: uid,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.text,
    required this.ac,
  });
  final IconData icon;
  final String text;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: ac.textMuted),
          const SizedBox(height: 12),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(color: ac.textMuted),
          ),
        ],
      ),
    );
  }
}
