import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/presentation/providers/comments_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_detail_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/reaction_providers.dart';
import 'package:unishare_mobile/features/post/presentation/providers/user_like_status_provider.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/ai_summary_panel.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/ask_ai_section.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/attachment_list.dart';
import 'package:unishare_mobile/features/post/domain/entities/comment.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/comment_tile.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post_snapshot.dart';
import 'package:unishare_mobile/features/saved/domain/usecases/save_post.dart';
import 'package:unishare_mobile/features/saved/domain/usecases/unsave_post.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/is_post_saved_provider.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/saved_post_repository_provider.dart';
import 'package:unishare_mobile/features/saved/presentation/widgets/save_button.dart';

final _coursePostsProvider = StreamProvider.autoDispose
    .family<List<Post>, ({String courseId, String excludeId})>((ref, args) {
      final ds = ref.watch(postFirestoreDatasourceProvider);
      return ds.watchPostsByCourse(args.courseId, excludeId: args.excludeId);
    });

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
  bool _commentsVisible = true;

  @override
  void initState() {
    super.initState();
    ref
        .read(incrementViewCountUseCaseProvider)
        .call(widget.postId)
        .ignore();
  }

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

  void _toggleComments() =>
      setState(() => _commentsVisible = !_commentsVisible);

  void _showComments() {
    if (!_commentsVisible) setState(() => _commentsVisible = true);
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
          commentsVisible: _commentsVisible,
          onToggleComments: _toggleComments,
          onShowComments: _showComments,
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
    required this.commentsVisible,
    required this.onToggleComments,
    required this.onShowComments,
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
  final bool commentsVisible;
  final VoidCallback onToggleComments;
  final VoidCallback onShowComments;

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

    final visibleCount = commentsVisible
        ? 1 + topLevel.length + (topLevel.isEmpty ? 1 : 0)
        : 1;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: visibleCount,
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
                  commentsVisible: commentsVisible,
                  onToggleComments: onToggleComments,
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
          onExpandComments: onShowComments,
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
    required this.commentsVisible,
    required this.onToggleComments,
  });

  final Post post;
  final bool isLiked;
  final bool isGuest;
  final VoidCallback onToggleLike;
  final int commentCount;
  final bool commentsVisible;
  final VoidCallback onToggleComments;

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

    final courseTag = post.tags.isNotEmpty ? post.tags.first : null;
    final topicTags = post.tags.length > 1 ? post.tags.sublist(1) : <String>[];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Type badge + course code ──────────────────────────────────────
          Row(
            children: [
              _PostTypeBadge(type: post.postType),
              if (courseTag != null) ...[
                const SizedBox(width: 8),
                Text(
                  courseTag.toUpperCase(),
                  style: AppTypography.mono(
                    base: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: appColors.amber,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // ── Title ─────────────────────────────────────────────────────────
          Text(
            post.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),

          // ── Year · Semester · Module ──────────────────────────────────────
          Text(
            'Year ${post.year} · Semester ${post.semester} · Module ${post.moduleNumber}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: appColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),

          // ── Topic chips (tags[1:]) ────────────────────────────────────────
          if (topicTags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: topicTags.map((t) => _TopicChip(label: t)).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // ── Author ────────────────────────────────────────────────────────
          _AuthorChip(post: post),
          const SizedBox(height: 12),

          // ── Stats: views · comments | save + copy link ────────────────────
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 15,
                color: appColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                '${post.viewsCount} ${post.viewsCount == 1 ? 'view' : 'views'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: appColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chat_bubble_outline,
                size: 15,
                color: appColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                '$commentCount ${commentCount == 1 ? 'comment' : 'comments'}',
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
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: 'https://unishare.app/posts/${post.id}',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Icon(Icons.link, size: 22, color: appColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── AI Summary ────────────────────────────────────────────────────
          AiSummaryPanel(status: post.summaryStatus, summary: post.summary),
          const SizedBox(height: 8),
          if (post.summaryStatus == SummaryStatus.done) ...[
            AskAiSection(postId: post.id, summary: post.summary!),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),

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
          const SizedBox(height: 16),

          // ── Reaction bar ──────────────────────────────────────────────────
          _ReactionBar(
            postId: post.id,
            isLiked: isLiked,
            likeCount: post.likesCount,
            reactionCounts: post.reactionCounts,
            isGuest: isGuest,
            onToggleLike: isGuest ? null : onToggleLike,
          ),
          const SizedBox(height: 20),
          Divider(color: Theme.of(context).dividerColor, height: 1),
          const SizedBox(height: 16),

          // ── More from this course ─────────────────────────────────────────
          _MoreFromCourse(courseId: post.courseId, excludeId: post.id),
          const SizedBox(height: 20),
          Divider(color: Theme.of(context).dividerColor, height: 1),
          const SizedBox(height: 12),

          // ── Comments heading (tap to collapse/expand) ─────────────────────
          GestureDetector(
            onTap: onToggleComments,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  const SizedBox(width: 4),
                  Icon(
                    commentsVisible ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: appColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
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
                [
                  if (post.departmentId != null &&
                      post.departmentId!.isNotEmpty)
                    post.departmentId!,
                  _relativeTime(post.createdAt),
                ].join(' · '),
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
    this.onExpandComments,
  });

  final bool isGuest;
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final String? replyingToName;
  final VoidCallback onCancelReply;
  final VoidCallback? onExpandComments;

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
                  onTap: onExpandComments,
                  // Grow up to 5 lines, then scroll internally — prevents
                  // the bar from pushing comments off-screen on long input.
                  maxLines: 5,
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

// ---------------------------------------------------------------------------
// Post type badge — NOTE (info/teal) or EXERCISE (amber)
// ---------------------------------------------------------------------------

class _PostTypeBadge extends StatelessWidget {
  const _PostTypeBadge({required this.type});

  final PostType type;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final isNote = type == PostType.lectureNote;
    final label = isNote ? 'NOTE' : 'EXERCISE';
    final color = isNote ? appColors.info : appColors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTypography.mono(
          base: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reaction bar — 6 interactive reaction buttons + total count
// ---------------------------------------------------------------------------

class _ReactionBar extends ConsumerWidget {
  const _ReactionBar({
    required this.postId,
    required this.isLiked,
    required this.likeCount,
    required this.reactionCounts,
    required this.isGuest,
    this.onToggleLike,
  });

  final String postId;
  final bool isLiked;
  final int likeCount;
  final Map<String, int> reactionCounts;
  final bool isGuest;
  final VoidCallback? onToggleLike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userReactions =
        ref.watch(userReactionsProvider(postId)).asData?.value ?? {};
    final scheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>()!;

    Future<void> handleReaction(String type) async {
      if (isGuest) return;
      try {
        await ref.read(reactionRepositoryProvider).toggleReaction(postId, type);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update reaction')),
          );
        }
      }
    }

    final total =
        likeCount + reactionCounts.values.fold(0, (sum, c) => sum + c);

    return Row(
      children: [
        _ReactionBtn(
          icon: Icons.thumb_up_alt_outlined,
          count: reactionCounts['thumbsUp'] ?? 0,
          isActive: userReactions.contains('thumbsUp'),
          activeColor: appColors.amber,
          onTap: isGuest ? null : () => handleReaction('thumbsUp'),
        ),
        const SizedBox(width: 6),
        _ReactionBtn(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          count: likeCount,
          isActive: isLiked,
          activeColor: scheme.error,
          onTap: onToggleLike,
        ),
        const SizedBox(width: 6),
        _ReactionBtn(
          icon: Icons.local_fire_department,
          count: reactionCounts['fire'] ?? 0,
          isActive: userReactions.contains('fire'),
          activeColor: appColors.amber,
          onTap: isGuest ? null : () => handleReaction('fire'),
        ),
        const SizedBox(width: 6),
        _ReactionBtn(
          icon: Icons.bolt,
          count: reactionCounts['bolt'] ?? 0,
          isActive: userReactions.contains('bolt'),
          activeColor: appColors.amber,
          onTap: isGuest ? null : () => handleReaction('bolt'),
        ),
        const SizedBox(width: 6),
        _ReactionBtn(
          icon: Icons.star_border,
          count: reactionCounts['star'] ?? 0,
          isActive: userReactions.contains('star'),
          activeColor: appColors.amber,
          onTap: isGuest ? null : () => handleReaction('star'),
        ),
        const SizedBox(width: 6),
        _ReactionBtn(
          icon: Icons.dangerous_outlined,
          count: reactionCounts['skull'] ?? 0,
          isActive: userReactions.contains('skull'),
          activeColor: appColors.amber,
          onTap: isGuest ? null : () => handleReaction('skull'),
        ),
        const SizedBox(width: 12),
        Text(
          '$total ${total == 1 ? 'reaction' : 'reactions'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: appColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ReactionBtn extends StatelessWidget {
  const _ReactionBtn({
    required this.icon,
    this.count = 0,
    this.isActive = false,
    this.activeColor,
    this.onTap,
  });

  final IconData icon;
  final int count;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final color = isActive
        ? (activeColor ?? appColors.amber)
        : appColors.textMuted;
    final hasCnt = count > 0;

    final iconWidget = Icon(icon, size: 16, color: color);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        width: hasCnt ? null : 36,
        padding: EdgeInsets.symmetric(horizontal: hasCnt ? 10 : 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.5)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: hasCnt
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconWidget,
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Center(child: iconWidget),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// More from this course
// ---------------------------------------------------------------------------

class _MoreFromCourse extends ConsumerWidget {
  const _MoreFromCourse({required this.courseId, required this.excludeId});

  final String courseId;
  final String excludeId;

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays >= 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays >= 7) return '${diff.inDays ~/ 7}w ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(
      _coursePostsProvider((courseId: courseId, excludeId: excludeId)),
    );
    final appColors = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final posts = postsAsync.asData?.value ?? [];

    if (posts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MORE FROM THIS COURSE',
          style: AppTypography.mono(
            base: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: appColors.textMuted,
              letterSpacing: 0.9,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: List.generate(posts.length, (i) {
              final p = posts[i];
              final isNote = p.postType == PostType.lectureNote;
              final dotColor = isNote ? appColors.info : appColors.amber;
              final typeLabel = isNote ? 'NOTE' : 'EXERCISE';
              final displayName = p.postingIdentity == PostingIdentity.anonymous
                  ? 'Anonymous'
                  : p.authorName;
              final isLast = i == posts.length - 1;
              return Column(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/posts/${p.id}', extra: p),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.title,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurface,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$displayName · ${_timeAgo(p.createdAt)}',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: appColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            typeLabel,
                            style: AppTypography.mono(
                              base: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: appColors.textMuted,
                                    letterSpacing: 0.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(color: Theme.of(context).dividerColor, height: 1),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
