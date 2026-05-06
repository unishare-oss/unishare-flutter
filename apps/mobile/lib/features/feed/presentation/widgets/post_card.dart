import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      onTap: () => context.push('/posts/${post.id}', extra: post),
      child: Container(
        color: Theme.of(context).cardColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopRow(context, appColors),
            const SizedBox(height: 6),
            _buildTitle(context),
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildTagsWrap(appColors),
            ],
            const SizedBox(height: 8),
            _buildAuthorRow(context, appColors),
            const SizedBox(height: 6),
            _buildMetaRow(appColors),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow(BuildContext context, AppColors appColors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _TypeBadge(type: post.postType),
        const SizedBox(width: 6),
        Text(
          post.courseId,
          style: GoogleFonts.firaCode(
            fontSize: 11,
            color: appColors.textMuted,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        Icon(
          Icons.bookmark_border_outlined,
          size: 18,
          color: appColors.textMuted,
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      post.title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTagsWrap(AppColors appColors) {
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
                style: GoogleFonts.firaCode(
                  fontSize: 10,
                  color: appColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildAuthorRow(BuildContext context, AppColors appColors) {
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
            style: GoogleFonts.firaCode(
              fontSize: 7,
              fontWeight: FontWeight.w600,
              color: appColors.amber,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          displayName,
          style: TextStyle(fontSize: 12, color: appColors.textSecondary),
        ),
        Text(
          ' · Year ${post.year}',
          style: TextStyle(fontSize: 12, color: appColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildMetaRow(AppColors appColors) {
    return Row(
      children: [
        Icon(Icons.favorite_border, size: 12, color: appColors.textMuted),
        const SizedBox(width: 3),
        Text(
          '${post.likesCount} likes',
          style: TextStyle(fontSize: 11, color: appColors.textMuted),
        ),
        Text(
          ' · ',
          style: TextStyle(fontSize: 11, color: appColors.textMuted),
        ),
        Text(
          _timeAgo(post.createdAt),
          style: TextStyle(fontSize: 11, color: appColors.textMuted),
        ),
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
        isNote ? 'NOTE' : 'EXERCISE',
        style: GoogleFonts.firaCode(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isNote ? appColors.info : appColors.amber,
          letterSpacing: 0.55,
        ),
      ),
    );
  }
}
