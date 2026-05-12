import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/saved/domain/entities/saved_post.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/saved_post_repository_provider.dart';
import 'package:unishare_mobile/features/saved/presentation/widgets/save_button.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class SavedPostCard extends ConsumerWidget {
  const SavedPostCard({super.key, required this.savedPost, this.onTap});

  final SavedPost savedPost;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = savedPost.snapshot;
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TypeBadge(postType: snapshot.postType),
                const SizedBox(width: 8),
                Text(
                  snapshot.courseId,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: appColors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                SaveButton(
                  isSaved: true,
                  onTap: () {
                    ref
                        .read(savedPostRepositoryProvider)
                        .unsavePost(savedPost.postId);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              snapshot.title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _AuthorAvatar(name: snapshot.authorName),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    snapshot.authorName.isEmpty
                        ? 'Anonymous'
                        : snapshot.authorName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: appColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 13,
                  color: appColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${snapshot.commentsCount} comments · ${_relativeTime(savedPost.savedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: appColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()} years ago';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()} months ago';
    if (diff.inDays >= 1) return '${diff.inDays} days ago';
    if (diff.inHours >= 1) return '${diff.inHours} hours ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes} minutes ago';
    return 'just now';
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.postType});
  final String postType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        postType.toUpperCase(),
        style: AppTypography.mono(
          base: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.name});
  final String name;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return CircleAvatar(
      radius: 10,
      backgroundColor: appColors.muted,
      child: name.isEmpty
          ? Icon(Icons.person_outline, size: 12, color: appColors.textMuted)
          : Text(
              _initials,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: appColors.textSecondary,
              ),
            ),
    );
  }
}
