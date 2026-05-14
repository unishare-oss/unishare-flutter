import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/presentation/providers/comments_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_detail_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/user_like_status_provider.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/attachment_list.dart';
import 'package:unishare_mobile/features/post/domain/entities/comment.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/comment_tile.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/like_button.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post_snapshot.dart';
import 'package:unishare_mobile/features/saved/domain/usecases/save_post.dart';
import 'package:unishare_mobile/features/saved/domain/usecases/unsave_post.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/is_post_saved_provider.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/saved_post_repository_provider.dart';
import 'package:unishare_mobile/features/saved/presentation/widgets/save_button.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId, this.seed});

  final String postId;
  final Post? seed;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _startReply(String commentId, String authorName) {
    ref
        .read(replyStateProvider(widget.postId).notifier)
        .startReply(commentId, authorName);
  }

  void _cancelReply() {
    ref.read(replyStateProvider(widget.postId).notifier).cancel();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    final parentId = ref.read(replyStateProvider(widget.postId))?.id;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(addCommentUseCaseProvider)
          .call(widget.postId, text, parentId: parentId);
      _commentController.clear();
      if (mounted) {
        ref.read(replyStateProvider(widget.postId).notifier).cancel();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to post comment: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(deleteCommentUseCaseProvider)
          .call(widget.postId, commentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete comment: $e')));
      }
    }
  }

  Future<void> _toggleLike() async {
    try {
      await ref.read(toggleLikeUseCaseProvider).call(widget.postId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to toggle like: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(
      postDetailProvider(widget.postId, seed: widget.seed),
    );
    final isGuest = ref.watch(guestModeProvider);
    final currentUid = ref.watch(currentUserProvider).asData?.value?.id;
    final replyTarget = ref.watch(replyStateProvider(widget.postId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(color: Theme.of(context).colorScheme.onSurface),
        titleSpacing: 0,
        title: _BreadcrumbBar(post: postAsync.whenOrNull(data: (p) => p)),
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          final appColors = Theme.of(context).extension<AppColors>()!;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: appColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Could not load post',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: appColors.textMuted),
                  ),
                ],
              ),
            ),
          );
        },
        data: (post) => _PostBody(
          post: post,
          isGuest: isGuest,
          currentUid: currentUid,
          onToggleLike: _toggleLike,
          commentController: _commentController,
          isSubmitting: _isSubmitting,
          onSubmitComment: _submitComment,
          replyingToName: replyTarget?.name,
          onReply: _startReply,
          onCancelReply: _cancelReply,
          onDeleteComment: _deleteComment,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Breadcrumb bar  Feed › CSC233 › LR Parsing
// ---------------------------------------------------------------------------

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({this.post});

  final Post? post;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;

    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.labelSmall?.copyWith(
      color: appColors.textMuted,
    );
    final sep = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        '›',
        style: theme.textTheme.labelSmall?.copyWith(color: appColors.textMuted),
      ),
    );

    final courseTag = (post?.tags.isNotEmpty ?? false)
        ? post!.tags.first
        : null;
    final rawTitle = post?.title ?? '';
    final truncTitle = rawTitle.length > 14
        ? '${rawTitle.substring(0, 14)}…'
        : rawTitle.isEmpty
        ? 'Post'
        : rawTitle;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => context.go('/feed'),
          child: Text('Feed', style: mutedStyle),
        ),
        if (courseTag != null) ...[
          sep,
          Flexible(
            child: Text(
              courseTag,
              style: mutedStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        sep,
        Flexible(
          child: Text(
            truncTitle,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Main post body
// ---------------------------------------------------------------------------

class _PostBody extends ConsumerWidget {
  const _PostBody({
    required this.post,
    required this.isGuest,
    this.currentUid,
    required this.onToggleLike,
    required this.commentController,
    required this.isSubmitting,
    required this.onSubmitComment,
    this.replyingToName,
    required this.onReply,
    required this.onCancelReply,
    required this.onDeleteComment,
  });

  final Post post;
  final bool isGuest;
  final String? currentUid;
  final VoidCallback onToggleLike;
  final TextEditingController commentController;
  final bool isSubmitting;
  final VoidCallback onSubmitComment;
  final String? replyingToName;
  final void Function(String commentId, String authorName) onReply;
  final VoidCallback onCancelReply;
  final void Function(String commentId) onDeleteComment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(commentsProvider(post.id));
    final likeStatusAsync = ref.watch(userLikeStatusProvider(post.id));

    final isLiked = likeStatusAsync.value ?? false;
    final allComments = commentsAsync.value ?? [];

    // Group into top-level comments and a parentId → replies map.
    final topLevel = allComments.where((c) => c.parentId == null).toList();
    final repliesMap = <String, List<Comment>>{};
    for (final c in allComments) {
      if (c.parentId != null) {
        repliesMap.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }

    final itemCount = 1 + topLevel.length + (topLevel.isEmpty ? 1 : 0);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _PostHeader(
                  post: post,
                  isLiked: isLiked,
                  isGuest: isGuest,
                  onToggleLike: onToggleLike,
                  commentCount: allComments
                      .where((c) => c.parentId == null)
                      .length,
                );
              }
              if (topLevel.isEmpty) return const _EmptyComments();
              final c = topLevel[index - 1];
              final isOwner = !isGuest && currentUid == c.authorId;
              return CommentTile(
                comment: c,
                replies: repliesMap[c.id] ?? [],
                currentUid: isGuest ? null : currentUid,
                onReply: isGuest ? null : () => onReply(c.id, c.authorName),
                onDelete: isOwner ? () => onDeleteComment(c.id) : null,
                onDeleteReply: isGuest ? null : (id) => onDeleteComment(id),
              );
            },
          ),
        ),
        _CommentInputBar(
          isGuest: isGuest,
          controller: commentController,
          isSubmitting: isSubmitting,
          onSubmit: onSubmitComment,
          replyingToName: replyingToName,
          onCancelReply: onCancelReply,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Post header — badges, title, tags, author, stats, AI summary, body, attachments
// ---------------------------------------------------------------------------

class _PostHeader extends ConsumerWidget {
  const _PostHeader({
    required this.post,
    required this.isLiked,
    required this.isGuest,
    required this.onToggleLike,
    required this.commentCount,
  });

  final Post post;
  final bool isLiked;
  final bool isGuest;
  final VoidCallback onToggleLike;
  final int commentCount;

  Future<void> _toggleSave(
    BuildContext context,
    WidgetRef ref,
    bool isSaved,
  ) async {
    final repository = ref.read(savedPostRepositoryProvider);
    try {
      if (isSaved) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSavedAsync = ref.watch(isPostSavedProvider(post.id));
    final isSaved = isSavedAsync.asData?.value ?? false;
    final appColors = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;

    // tags[0] → teal course badge alongside NOTE; tags[1:] → dark topic chips
    final courseTag = post.tags.isNotEmpty ? post.tags.first : null;
    final topicTags = post.tags.length > 1 ? post.tags.sublist(1) : <String>[];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── NOTE + course badges ──────────────────────────────────────────
          Row(
            children: [
              const _TealBadge(label: 'NOTE'),
              if (courseTag != null) ...[
                const SizedBox(width: 6),
                _TealBadge(label: courseTag.toUpperCase()),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // ── Title ─────────────────────────────────────────────────────────
          Text(
            post.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // ── Topic chips (tags[1:]) ─────────────────────────────────────────
          if (topicTags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: topicTags.map((t) => _TopicChip(label: t)).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // ── Author ────────────────────────────────────────────────────────
          _AuthorChip(post: post),
          const SizedBox(height: 12),

          // ── Stats: likes + comments + save ───────────────────────────────
          Row(
            children: [
              LikeButton(
                isLiked: isLiked,
                count: post.likesCount,
                onTap: onToggleLike,
                enabled: !isGuest,
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: appColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                '$commentCount',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: appColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              SaveButton(
                isSaved: isSaved,
                onTap: () => _toggleSave(context, ref, isSaved),
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── AI Summary ────────────────────────────────────────────────────
          const _AiSummaryCard(),
          const SizedBox(height: 16),

          // ── DESCRIPTION ───────────────────────────────────────────────────
          _SectionLabel(label: 'DESCRIPTION'),
          const SizedBox(height: 8),
          Text(
            post.body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              height: 1.6,
            ),
          ),

          // ── ATTACHMENTS ───────────────────────────────────────────────────
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel(label: 'ATTACHMENTS'),
            const SizedBox(height: 8),
            AttachmentList(
              mediaUrls: post.mediaUrls,
              mediaTypes: post.mediaTypes,
            ),
          ],

          const SizedBox(height: 20),
          Divider(color: Theme.of(context).dividerColor, height: 1),
          const SizedBox(height: 12),

          // ── Comments heading ──────────────────────────────────────────────
          Text(
            '$commentCount ${commentCount == 1 ? 'COMMENT' : 'COMMENTS'}',
            style: AppTypography.mono(
              base: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: appColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Teal badge — NOTE, CSC233 (info color, Fira Code)
// ---------------------------------------------------------------------------

class _TealBadge extends StatelessWidget {
  const _TealBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: appColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: appColors.info.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTypography.mono(
          base: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: appColors.info,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dark topic chip — concurrency, data structures, etc.
// ---------------------------------------------------------------------------

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label — DESCRIPTION, ATTACHMENTS
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Text(
      label,
      style: AppTypography.mono(
        base: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: appColors.textMuted,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Author chip
// ---------------------------------------------------------------------------

class _AuthorChip extends StatelessWidget {
  const _AuthorChip({required this.post});

  final Post post;

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: appColors.amberSubtle,
          backgroundImage: post.authorAvatar.isNotEmpty
              ? CachedNetworkImageProvider(post.authorAvatar)
              : null,
          child: post.authorAvatar.isEmpty
              ? Text(
                  post.authorName.isNotEmpty
                      ? post.authorName[0].toUpperCase()
                      : '?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: appColors.amber,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                _relativeTime(post.createdAt),
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: appColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// AI Summary card — collapsible, amber accent border
// ---------------------------------------------------------------------------

class _AiSummaryCard extends StatefulWidget {
  const _AiSummaryCard();

  @override
  State<_AiSummaryCard> createState() => _AiSummaryCardState();
}

class _AiSummaryCardState extends State<_AiSummaryCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: appColors.amberSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appColors.amber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — tappable to expand/collapse
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(8),
              bottom: _expanded ? Radius.zero : const Radius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: appColors.amber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AI SUMMARY',
                    style: AppTypography.mono(
                      base: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: appColors.amber,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: appColors.amber,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            Divider(height: 1, color: appColors.amber.withValues(alpha: 0.25)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                // TODO: wire to real AI summary API
                'AI-generated summary not yet available for this post.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: TextButton.icon(
                onPressed: () {},
                icon: Icon(
                  Icons.auto_awesome_rounded,
                  size: 13,
                  color: appColors.amber,
                ),
                label: Text(
                  'ASK AI',
                  style: AppTypography.mono(
                    base: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: appColors.amber,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty comments placeholder
// ---------------------------------------------------------------------------

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Text(
        'No comments yet. Be the first to comment.',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: appColors.textMuted),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comment input bar
// ---------------------------------------------------------------------------

class _CommentInputBar extends StatelessWidget {
  const _CommentInputBar({
    required this.isGuest,
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
    this.replyingToName,
    required this.onCancelReply,
  });

  final bool isGuest;
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final String? replyingToName;
  final VoidCallback onCancelReply;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final topBorder = BorderSide(color: Theme.of(context).dividerColor);

    if (isGuest) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          border: Border(top: topBorder),
        ),
        child: Text(
          'Sign in to comment',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: appColors.textMuted),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        border: Border(top: topBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (replyingToName != null) ...[
            Row(
              children: [
                Icon(Icons.reply, size: 14, color: appColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Replying to $replyingToName',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: appColors.textMuted),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onCancelReply,
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: appColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Write a comment…',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: appColors.textMuted,
                    ),
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  textInputAction: TextInputAction.newline,
                  maxLines: null,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                width: 44,
                child: FilledButton(
                  onPressed: isSubmitting ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: appColors.amber,
                    foregroundColor: scheme.onPrimary,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: isSubmitting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.send, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
