import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/post.dart';
import '../../domain/entities/post_type.dart';
import '../providers/post_feed_provider.dart';

class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post, required this.currentUserId});

  final Post post;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final border = theme.dividerColor;

    return InkWell(
      onTap: () => context.push('/feed/posts/${post.id}'),
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: border, width: 0.8)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetaBadgeRow(post: post),
                  const SizedBox(height: 6),
                  Text(
                    post.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (post.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _TagRow(tags: post.tags),
                  ],
                  const SizedBox(height: 10),
                  _FooterRow(post: post, ref: ref, currentUserId: currentUserId),
                ],
              ),
            ),
            if (currentUserId != null && post.authorId == currentUserId) ...[
              const SizedBox(width: 8),
              _DeleteMenu(
                onDelete: () => ref
                    .read(postFeedProvider.notifier)
                    .deletePost(post.id)
                    .catchError((_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not delete post')),
                    );
                  }
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaBadgeRow extends StatelessWidget {
  const _MetaBadgeRow({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _TypeBadge(type: post.type),
        if (post.courseCode != null && post.courseCode!.isNotEmpty)
          _CourseCode(code: post.courseCode!),
        if (post.courseDepartment != null && post.courseDepartment!.isNotEmpty)
          Text(
            post.courseDepartment!,
            style: GoogleFonts.firaCode(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(140),
            ),
          ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final PostType type;

  Color _color(BuildContext context) {
    final theme = Theme.of(context);
    switch (type) {
      case PostType.note:
        return theme.colorScheme.primary.withBlue(200);
      case PostType.exercise:
        return const Color(0xFF16A34A);
      case PostType.pastExam:
        return const Color(0xFFD97706);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.label,
        style: GoogleFonts.firaCode(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _CourseCode extends StatelessWidget {
  const _CourseCode({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final amber = Theme.of(context).colorScheme.primary;
    return Text(
      code,
      style: GoogleFonts.firaCode(
        fontSize: 12,
        color: amber,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tags});
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: theme.dividerColor,
                  width: 0.8,
                ),
              ),
              child: Text(
                tag,
                style: GoogleFonts.firaCode(
                  fontSize: 10,
                  color: theme.textTheme.bodySmall?.color?.withAlpha(160),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FooterRow extends StatelessWidget {
  const _FooterRow({
    required this.post,
    required this.ref,
    required this.currentUserId,
  });
  final Post post;
  final WidgetRef ref;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = GoogleFonts.firaCode(
      fontSize: 11,
      color: theme.textTheme.bodySmall?.color?.withAlpha(140),
    );
    const dot = '·';

    return Wrap(
      spacing: 6,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _AuthorChip(post: post),
        Text(dot, style: mutedStyle),
        Text(_relativeTime(post.createdAt), style: mutedStyle),
        Text(dot, style: mutedStyle),
        _LikeChip(post: post, ref: ref),
        if (post.commentCount > 0) ...[
          Text(dot, style: mutedStyle),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 12,
                color: theme.textTheme.bodySmall?.color?.withAlpha(140),
              ),
              const SizedBox(width: 3),
              Text('${post.commentCount}', style: mutedStyle),
            ],
          ),
        ],
      ],
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _AuthorChip extends StatelessWidget {
  const _AuthorChip({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = post.authorName.isNotEmpty
        ? post.authorName[0].toUpperCase()
        : '?';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 8,
          backgroundColor: theme.colorScheme.primary.withAlpha(40),
          child: Text(
            initials,
            style: GoogleFonts.firaCode(
              fontSize: 8,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          post.authorName,
          style: GoogleFonts.firaCode(
            fontSize: 11,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}

class _LikeChip extends StatelessWidget {
  const _LikeChip({required this.post, required this.ref});
  final Post post;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final liked = post.isLikedByCurrentUser;
    final color = liked
        ? theme.colorScheme.error
        : theme.textTheme.bodySmall?.color?.withAlpha(140);

    return GestureDetector(
      onTap: () => ref
          .read(postFeedProvider.notifier)
          .toggleLike(post.id, liked: !liked),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            liked ? Icons.favorite : Icons.favorite_border,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            '${post.likesCount}',
            style: GoogleFonts.firaCode(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}

class _DeleteMenu extends StatelessWidget {
  const _DeleteMenu({required this.onDelete});
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 18,
        color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(140),
      ),
      onSelected: (value) {
        if (value == 'delete') onDelete();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'delete', child: Text('Delete post')),
      ],
    );
  }
}
