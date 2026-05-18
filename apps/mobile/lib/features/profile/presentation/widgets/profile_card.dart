import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/earned_badges_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/user_gamification_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/earn_moment_modal.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/level_chip.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/profile_achievements_section.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/title_chip.dart';
import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/departments_provider.dart';
import 'package:unishare_mobile/features/profile/presentation/providers/profile_stats_provider.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/saved_posts_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class ProfileCard extends ConsumerWidget {
  const ProfileCard({super.key, required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);

    final depts = ref.watch(departmentsProvider).asData?.value ?? [];
    final deptName = depts
        .firstWhere(
          (d) => d.id == user.departmentId,
          orElse: () => (id: '', name: ''),
        )
        .name;
    final postsAsync = ref.watch(userPostsCountProvider(user.id));
    final commentsAsync = ref.watch(userCommentsCountProvider(user.id));
    final savedCount = ref.watch(savedPostsProvider).asData?.value.length ?? 0;

    final joinedYear = user.enrollmentYear ?? DateTime.now().year;
    final yearLevel = (DateTime.now().year - joinedYear) + 1;
    final cs = Theme.of(context).colorScheme;

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
              ProfileAvatar(photoUrl: user.photoUrl, name: user.name),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NameRow(user: user),
                    Consumer(
                      builder: (context, ref, _) {
                        final g = ref
                            .watch(userGamificationProvider(user.id))
                            .asData
                            ?.value;
                        final selectedId = g?.selectedTitle;
                        if (selectedId == null || selectedId.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        // `selectedTitle` stores the badge id; resolve to
                        // the human-readable badge name from the catalog.
                        // Falls back to the id (so the chip never disappears
                        // while the catalog is still loading).
                        final catalog =
                            ref.watch(badgeCatalogProvider).asData?.value ??
                            const [];
                        final match = catalog
                            .where((b) => b.id == selectedId)
                            .cast<AchievementBadge?>()
                            .firstWhere((_) => true, orElse: () => null);
                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: TitleChip(title: match?.name ?? selectedId),
                        );
                      },
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: AppTypography.mono(
                        base: theme.textTheme.bodySmall?.copyWith(
                          color: ac.textMuted,
                        ),
                      ),
                    ),
                    if ((user.bio ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(user.bio!, style: theme.textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        ProfileBadge(user.role.toUpperCase()),
                        if (deptName.isNotEmpty)
                          ProfileBadge(deptName.toUpperCase()),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Joined $joinedYear',
                      style: AppTypography.mono(
                        base: theme.textTheme.labelSmall?.copyWith(
                          color: ac.textMuted,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Year $yearLevel Student',
                      style: AppTypography.mono(
                        base: theme.textTheme.labelSmall?.copyWith(
                          color: ac.amber,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 8),
          Row(
            children: [
              ProfileStat(
                label: 'POSTS',
                value: postsAsync.asData?.value.toString() ?? '—',
              ),
              const SizedBox(width: 28),
              ProfileStat(
                label: 'COMMENTS',
                value: commentsAsync.asData?.value.toString() ?? '—',
              ),
              const SizedBox(width: 28),
              ProfileStat(label: 'SAVED', value: savedCount.toString()),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 8),
          ProfileAchievementsSection(uid: user.id),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar
// ---------------------------------------------------------------------------

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.photoUrl, required this.name});
  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          placeholder: (_, _) => _FallbackAvatar(name: name, ac: ac),
          errorWidget: (_, _, _) => _FallbackAvatar(name: name, ac: ac),
        ),
      );
    }
    return _FallbackAvatar(name: name, ac: ac);
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.name, required this.ac});
  final String name;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Container(
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
}

// ---------------------------------------------------------------------------
// Badge
// ---------------------------------------------------------------------------

class ProfileBadge extends StatelessWidget {
  const ProfileBadge(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.onSurface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.mono(
          base: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: cs.surface,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat
// ---------------------------------------------------------------------------

class ProfileStat extends StatelessWidget {
  const ProfileStat({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.mono(
            base: theme.textTheme.labelSmall?.copyWith(
              color: ac.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Name row
// ---------------------------------------------------------------------------

/// Renders the user's name on the left and a [LevelChip] on the right.
///
/// Easter egg: tap the name 7 times within 3 seconds (only on your own
/// profile) to reveal a "replay last earn" debug button beside the chip.
/// The button re-shows the [EarnMomentModal] for the most recently
/// earned badge so the burst animation can be retested without messing
/// with Firestore. No server writes happen — the modal is local-only.
class _NameRow extends ConsumerStatefulWidget {
  const _NameRow({required this.user});
  final AppUser user;

  @override
  ConsumerState<_NameRow> createState() => _NameRowState();
}

class _NameRowState extends ConsumerState<_NameRow> {
  static const _tapThreshold = 7;
  static const _tapWindow = Duration(seconds: 3);

  int _taps = 0;
  DateTime? _firstTap;
  bool _replayUnlocked = false;

  void _handleTap() {
    final now = DateTime.now();
    if (_firstTap == null || now.difference(_firstTap!) > _tapWindow) {
      _firstTap = now;
      _taps = 1;
    } else {
      _taps += 1;
    }
    if (_taps >= _tapThreshold && !_replayUnlocked) {
      setState(() => _replayUnlocked = true);
    }
  }

  Future<void> _replayLastEarn() async {
    final uid = widget.user.id;
    final earned =
        ref.read(earnedBadgesProvider(uid)).asData?.value ?? const [];
    final catalog = ref.read(badgeCatalogProvider).asData?.value ?? const [];
    if (earned.isEmpty || catalog.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No earned badges yet.')));
      return;
    }
    // earnedBadges stream is ordered earnedAt desc — first entry is newest.
    final latest = earned.first;
    final badge = catalog.firstWhere(
      (b) => b.id == latest.badgeId,
      orElse: () => AchievementBadge(
        id: latest.badgeId,
        name: latest.badgeId,
        description: '',
        glyph: 'sparkle',
        points: latest.pointsAwarded,
        tier: BadgeTier.progression,
        category: BadgeCategory.content,
        condition: const BadgeCondition(statKey: 'postsCreated', threshold: 0),
        order: 0,
        active: true,
      ),
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          EarnMomentModal(badge: badge, points: latest.pointsAwarded),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final currentUid = ref.watch(authStateProvider).asData?.value?.id;
    final isOwnProfile = currentUid == widget.user.id;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isOwnProfile ? _handleTap : null,
            child: Text(
              widget.user.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (isOwnProfile && _replayUnlocked) ...[
          IconButton(
            tooltip: 'Replay last earn',
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(PhosphorIconsThin.sparkle, color: ac.amber),
            onPressed: _replayLastEarn,
          ),
          const SizedBox(width: 4),
        ],
        Consumer(
          builder: (context, ref, _) {
            final g = ref
                .watch(userGamificationProvider(widget.user.id))
                .asData
                ?.value;
            return LevelChip(
              level: g?.level ?? 1,
              onTap: () => context.push('/achievements/${widget.user.id}'),
            );
          },
        ),
      ],
    );
  }
}
