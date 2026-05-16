import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
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
                    Text(
                      user.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
