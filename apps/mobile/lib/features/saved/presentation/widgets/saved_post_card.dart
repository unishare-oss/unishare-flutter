import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
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
    final appColors = Theme.of(context).extension<AppColors>()!;
    final type = PostType.fromName(postType);
    final isNote = type == PostType.lectureNote;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isNote
            ? appColors.info.withValues(alpha: 0.12)
            : appColors.amberSubtle,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.displayLabel,
        style: AppTypography.mono(
          base: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: isNote ? appColors.info : appColors.amber,
            letterSpacing: 0.55,
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
