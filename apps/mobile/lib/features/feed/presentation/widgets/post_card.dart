import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/achievements/presentation/providers/public_user_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/level_chip.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post_snapshot.dart';
import 'package:unishare_mobile/features/saved/domain/usecases/save_post.dart';
import 'package:unishare_mobile/features/saved/domain/usecases/unsave_post.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/is_post_saved_provider.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/saved_post_repository_provider.dart';
import 'package:unishare_mobile/features/saved/presentation/widgets/save_button.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post, this.suppressAuthorTapForUid});

  final Post post;

  /// When set, suppresses the tappable author-name link if `post.authorId`
  /// matches. Used by the public profile screen so visiting Alice's page
  /// and tapping a post by Alice doesn't stack another `/profile/<Alice>`
  /// on top.
  final String? suppressAuthorTapForUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSavedAsync = ref.watch(isPostSavedProvider(post.id));
    final isSaved = isSavedAsync.asData?.value ?? false;
    final appColors = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      onTap: () => context.push('/posts/${post.id}', extra: post),
      child: Container(
        color: Theme.of(context).cardColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopRow(context, appColors, isSaved, ref),
            const SizedBox(height: 6),
            _buildTitle(context),
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildTagsWrap(context, appColors),
            ],
            const SizedBox(height: 8),
            _buildAuthorRow(context, appColors, ref),
            const SizedBox(height: 6),
            _buildMetaRow(context, appColors),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSave(
    BuildContext context,
    WidgetRef ref,
    bool currentlySaved,
  ) async {
    final repository = ref.read(savedPostRepositoryProvider);
    try {
      if (currentlySaved) {
        await UnsavePost(repository).call(post.id);
      } else {
        await SavePost(repository).call(
          post.id,
          SavedPostSnapshot(
            title: post.title,
            authorName: post.authorName,
            authorAvatar: post.authorAvatar,
            courseId: post.courseId,
            postType: post.postType.name,
            tags: post.tags,
            commentsCount: 0,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update saved post')),
        );
      }
    }
  }

  Widget _buildTopRow(
    BuildContext context,
    AppColors appColors,
    bool isSaved,
    WidgetRef ref,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _TypeBadge(type: post.postType),
        const SizedBox(width: 6),
        Text(
          post.courseId,
          style: AppTypography.mono(
            base: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: appColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const Spacer(),
        SaveButton(
          isSaved: isSaved,
          onTap: () => _toggleSave(context, ref, isSaved),
          size: 18,
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      post.title,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTagsWrap(BuildContext context, AppColors appColors) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: post.tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: appColors.muted,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tag,
                style: AppTypography.mono(
                  base: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: appColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildAuthorRow(
    BuildContext context,
    AppColors appColors,
    WidgetRef ref,
  ) {
    final isAnonymous = post.postingIdentity == PostingIdentity.anonymous;
    final initials = isAnonymous
        ? '?'
        : post.authorName.isNotEmpty
        ? post.authorName[0].toUpperCase()
        : '?';
    final displayName = isAnonymous ? 'Anonymous' : post.authorName;

    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: appColors.amberSubtle,
          child: Text(
            initials,
            style: AppTypography.mono(
              base: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: appColors.amber,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Author name is tappable for non-anonymous posts — opens that
        // user's public profile. Wrapped in a GestureDetector (not
        // InkWell) because the whole card already absorbs taps via the
        // top-level GestureDetector; we just intercept this region.
        if (isAnonymous || suppressAuthorTapForUid == post.authorId)
          Text(
            displayName,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: appColors.textSecondary),
          )
        else
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push('/profile/${post.authorId}'),
            child: Text(
              displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: appColors.textSecondary,
                decoration: TextDecoration.underline,
                decorationColor: appColors.textMuted,
                decorationStyle: TextDecorationStyle.dotted,
              ),
            ),
          ),
        if (!isAnonymous) ...[..._authorLevelChip(ref)],
        Text(
          ' · Year ${post.year}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: appColors.textMuted),
        ),
      ],
    );
  }

  /// Returns either `[SizedBox(6), LevelChip(...)]` when the author has
  /// a renderable level, or an empty list. Keeps the chip width-stable
  /// at the call site.
  List<Widget> _authorLevelChip(WidgetRef ref) {
    final pu = ref.watch(publicUserProvider(post.authorId)).asData?.value;
    if (pu == null || pu.level < 2) return const [];
    return [const SizedBox(width: 6), LevelChip(level: pu.level)];
  }

  Widget _buildMetaRow(BuildContext context, AppColors appColors) {
    final metaStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: appColors.textMuted);
    return Row(
      children: [
        Icon(Icons.favorite_border, size: 12, color: appColors.textMuted),
        const SizedBox(width: 3),
        Text('${post.likesCount} likes', style: metaStyle),
        Text(' · ', style: metaStyle),
        Text(_timeAgo(post.createdAt), style: metaStyle),
      ],
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays >= 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final PostType type;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
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
