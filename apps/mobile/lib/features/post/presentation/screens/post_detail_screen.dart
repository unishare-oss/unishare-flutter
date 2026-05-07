import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../auth/presentation/providers/guest_mode_provider.dart';
import '../../domain/entities/post.dart';
import '../providers/comments_provider.dart';
import '../providers/post_detail_provider.dart';
import '../providers/post_repository_provider.dart';
import '../providers/user_like_status_provider.dart';
import '../widgets/attachment_list.dart';
import '../widgets/comment_tile.dart';

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

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(addCommentUseCaseProvider).call(widget.postId, text);
      _commentController.clear();
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(color: scheme.onSurface),
        titleSpacing: 4,
        title: Text(
          postAsync.whenOrNull(data: (p) => p.title) ?? '',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBody(error: error),
        data: (post) => _PostBody(
          post: post,
          isGuest: isGuest,
          onToggleLike: _toggleLike,
          commentController: _commentController,
          isSubmitting: _isSubmitting,
          onSubmitComment: _submitComment,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error body
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: appColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Could not load post',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: appColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post body — full-page scroll: post content → comments → input → empty state
// ─────────────────────────────────────────────────────────────────────────────

class _PostBody extends ConsumerWidget {
  const _PostBody({
    required this.post,
    required this.isGuest,
    required this.onToggleLike,
    required this.commentController,
    required this.isSubmitting,
    required this.onSubmitComment,
  });

  final Post post;
  final bool isGuest;
  final VoidCallback onToggleLike;
  final TextEditingController commentController;
  final bool isSubmitting;
  final VoidCallback onSubmitComment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(commentsProvider(post.id));
    final likeStatusAsync = ref.watch(userLikeStatusProvider(post.id));

    final isLiked = likeStatusAsync.value ?? false;
    final comments = commentsAsync.value ?? [];
    final hasComments = comments.isNotEmpty;

    // layout: [post content] [comments…] [input] [empty state?]
    final itemCount = 2 + comments.length + (hasComments ? 0 : 1);

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _PostContent(
            post: post,
            isLiked: isLiked,
            isGuest: isGuest,
            onToggleLike: onToggleLike,
            commentCount: comments.length,
          );
        }
        if (hasComments && index <= comments.length) {
          return CommentTile(comment: comments[index - 1]);
        }
        if (index == comments.length + 1) {
          return _CommentInputSection(
            isGuest: isGuest,
            controller: commentController,
            isSubmitting: isSubmitting,
            onSubmit: onSubmitComment,
          );
        }
        return const _EmptyComments();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post content (index 0 in ListView)
// ─────────────────────────────────────────────────────────────────────────────

class _PostContent extends StatelessWidget {
  const _PostContent({
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

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;

    // tags[0] = course code (badge); tags[1+] = topic chips
    final courseTag = post.tags.isNotEmpty ? post.tags.first : null;
    final topicTags = post.tags.length > 1 ? post.tags.sublist(1) : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Breadcrumb ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: _Breadcrumb(courseTag: courseTag, title: post.title),
        ),
        const SizedBox(height: 14),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── NOTE badge + course code label ────────────────────────
              Row(
                children: [
                  const _TealBadge(label: 'NOTE'),
                  if (courseTag != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      courseTag.toUpperCase(),
                      style: AppTypography.mono(
                        base: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: appColors.amber,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // ── Title ─────────────────────────────────────────────────
              Text(
                post.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),

              // ── Subtitle: Year / Semester / Module ────────────────────
              // TODO(post-detail): source from course metadata provider
              Text(
                'Year 2 · Semester 2 · Module 2',
                style: TextStyle(fontSize: 13, color: appColors.textMuted),
              ),
              const SizedBox(height: 12),

              // ── Topic chips ───────────────────────────────────────────
              if (topicTags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: topicTags.map((t) => _TopicChip(label: t)).toList(),
                ),
                const SizedBox(height: 14),
              ],

              // ── Author row ────────────────────────────────────────────
              _AuthorRow(post: post),
              const SizedBox(height: 12),

              // ── Stats row ─────────────────────────────────────────────
              _StatsRow(post: post, commentCount: commentCount),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── AI Summary card ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const _AiSummaryCard(),
        ),
        const SizedBox(height: 20),

        // ── DESCRIPTION ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel(label: 'DESCRIPTION'),
              const SizedBox(height: 8),
              Text(
                post.body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),

        // ── ATTACHMENTS ───────────────────────────────────────────────
        if (post.mediaUrls.isNotEmpty) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel(label: 'ATTACHMENTS'),
                const SizedBox(height: 8),
                AttachmentList(
                  mediaUrls: post.mediaUrls,
                  mediaTypes: post.mediaTypes,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        Divider(color: Theme.of(context).dividerColor, height: 1),
        const SizedBox(height: 16),

        // ── Reactions ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ReactionsRow(
            post: post,
            isLiked: isLiked,
            isGuest: isGuest,
            onToggleLike: onToggleLike,
          ),
        ),
        const SizedBox(height: 16),
        Divider(color: Theme.of(context).dividerColor, height: 1),
        const SizedBox(height: 20),

        // ── MORE FROM THIS COURSE ─────────────────────────────────────
        const _MoreFromThisCourse(),
        const SizedBox(height: 20),
        Divider(color: Theme.of(context).dividerColor, height: 1),
        const SizedBox(height: 12),

        // ── Comments heading ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            '$commentCount ${commentCount == 1 ? 'COMMENT' : 'COMMENTS'}',
            style: AppTypography.mono(
              base: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: appColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Breadcrumb  Feed › CSC217 › Chapter 7
// ─────────────────────────────────────────────────────────────────────────────

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.courseTag, required this.title});

  final String? courseTag;
  final String title;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;

    const sepStyle = TextStyle(fontSize: 12, color: Colors.grey);
    final linkStyle = TextStyle(fontSize: 12, color: appColors.amber);
    final boldStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        GestureDetector(
          onTap: () => context.go('/feed'),
          child: Text('Feed', style: linkStyle),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('>', style: sepStyle),
        ),
        if (courseTag != null) ...[
          Text(courseTag!.toUpperCase(), style: linkStyle),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('>', style: sepStyle),
          ),
        ],
        Text(title, style: boldStyle),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Teal badge — NOTE, CSC217
// ─────────────────────────────────────────────────────────────────────────────

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
          base: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: appColors.info,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Topic chip — concurrency, data structures …
// ─────────────────────────────────────────────────────────────────────────────

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Author row  [avatar]  Name / dept · time
// ─────────────────────────────────────────────────────────────────────────────

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.post});
  final Post post;

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return 'about ${diff.inDays ~/ 7} week(s) ago';
    return 'about ${diff.inDays ~/ 30} month(s) ago';
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: appColors.amber,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.authorName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            // TODO(post-detail): replace placeholder with user-profile department
            Text(
              'Computer Science · ${_relativeTime(post.createdAt)}',
              style: TextStyle(fontSize: 12, color: appColors.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats row  👁 N views · · · [bookmark] [share]
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.post, required this.commentCount});
  final Post post;
  final int commentCount;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        Icon(Icons.visibility_outlined, size: 16, color: appColors.textMuted),
        const SizedBox(width: 4),
        Text(
          '${post.likesCount} views',
          style: TextStyle(fontSize: 13, color: appColors.textMuted),
        ),
        const SizedBox(width: 14),
        Icon(Icons.chat_bubble_outline, size: 16, color: appColors.textMuted),
        const SizedBox(width: 4),
        Text(
          '$commentCount ${commentCount == 1 ? 'comment' : 'comments'}',
          style: TextStyle(fontSize: 13, color: appColors.textMuted),
        ),
        const Spacer(),
        _StatsIconButton(
          icon: Icons.bookmark_border_rounded,
          onTap: () {},
          color: appColors.textMuted,
        ),
        const SizedBox(width: 4),
        _StatsIconButton(
          icon: Icons.link_rounded,
          onTap: () {},
          color: appColors.textMuted,
        ),
      ],
    );
  }
}

class _StatsIconButton extends StatelessWidget {
  const _StatsIconButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label — DESCRIPTION / ATTACHMENTS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Text(
      label,
      style: AppTypography.mono(
        base: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: appColors.textMuted,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Summary card — collapsible, bullet points, ASK AI button
// ─────────────────────────────────────────────────────────────────────────────

class _AiSummaryCard extends StatefulWidget {
  const _AiSummaryCard();

  @override
  State<_AiSummaryCard> createState() => _AiSummaryCardState();
}

class _AiSummaryCardState extends State<_AiSummaryCard> {
  bool _expanded = true;

  // Placeholder summary bullets until AI API is wired.
  static const _bullets = [
    'Key concepts and definitions covered in this module.',
    'Important algorithms, data structures, and their trade-offs.',
    'Common patterns and use cases discussed in lectures.',
  ];

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: appColors.amberSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appColors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
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
                    size: 14,
                    color: appColors.amber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AI SUMMARY',
                    style: AppTypography.mono(
                      base: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: appColors.amber,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: appColors.amber,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            // Intro text
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Text(
                'AI-generated summary is not yet available for this post.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),

            // Bullet points
            ..._bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5, right: 8),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: appColors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        b,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // ASK AI button — full-width outlined
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: appColors.amber,
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ASK AI',
                      style: AppTypography.mono(
                        base: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: appColors.amber,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.expand_more, size: 16, color: appColors.amber),
                  ],
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 36),
                  side: BorderSide(
                    color: appColors.amber.withValues(alpha: 0.5),
                  ),
                  foregroundColor: appColors.amber,
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reactions row — 6 circular outline buttons + "N reaction(s)" on the right
// ─────────────────────────────────────────────────────────────────────────────

class _ReactionsRow extends StatelessWidget {
  const _ReactionsRow({
    required this.post,
    required this.isLiked,
    required this.isGuest,
    required this.onToggleLike,
  });

  final Post post;
  final bool isLiked;
  final bool isGuest;
  final VoidCallback onToggleLike;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final borderColor = Theme.of(context).dividerColor;
    final iconColor = appColors.textMuted;
    final likeCount = post.likesCount;

    return Row(
      children: [
        _ReactionButton(
          icon: isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
          iconColor: isLiked ? appColors.amber : iconColor,
          borderColor: borderColor,
          onTap: isGuest ? () {} : onToggleLike,
        ),
        const SizedBox(width: 6),
        _ReactionButton(
          icon: Icons.favorite_border_rounded,
          iconColor: iconColor,
          borderColor: borderColor,
          onTap: () {},
        ),
        const SizedBox(width: 6),
        _ReactionButton(
          icon: Icons.thumb_down_outlined,
          iconColor: iconColor,
          borderColor: borderColor,
          onTap: () {},
          count: likeCount > 0 ? likeCount : null,
        ),
        const SizedBox(width: 6),
        _ReactionButton(
          icon: Icons.bolt_rounded,
          iconColor: iconColor,
          borderColor: borderColor,
          onTap: () {},
        ),
        const SizedBox(width: 6),
        _ReactionButton(
          icon: Icons.star_border_rounded,
          iconColor: iconColor,
          borderColor: borderColor,
          onTap: () {},
        ),
        const SizedBox(width: 6),
        _ReactionButton(
          icon: Icons.sentiment_satisfied_alt_outlined,
          iconColor: iconColor,
          borderColor: borderColor,
          onTap: () {},
        ),
        const Spacer(),
        Text(
          '$likeCount ${likeCount == 1 ? 'reaction' : 'reactions'}',
          style: TextStyle(
            fontSize: 13,
            color: appColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final hasCount = count != null && count! > 0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: hasCount ? 10 : 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor),
            if (hasCount) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  color: iconColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Comment input section (scroll item after comments)
// ─────────────────────────────────────────────────────────────────────────────

class _CommentInputSection extends StatelessWidget {
  const _CommentInputSection({
    required this.isGuest,
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final bool isGuest;
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text field
          TextField(
            controller: isGuest ? null : controller,
            enabled: !isGuest,
            decoration: InputDecoration(
              hintText: 'Write a comment...',
              hintStyle: TextStyle(
                color: appColors.textMuted,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              fillColor: scheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            textInputAction: TextInputAction.newline,
            maxLines: null,
            minLines: 3,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: 8),

          // Submit row
          Row(
            children: [
              Text(
                'Shift · Enter to submit',
                style: TextStyle(fontSize: 11, color: appColors.textMuted),
              ),
              const Spacer(),
              FilledButton(
                onPressed: (isGuest || isSubmitting) ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: appColors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                child: isSubmitting
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Post'),
              ),
            ],
          ),

          // Guest sign-in prompt
          if (isGuest) ...[
            const SizedBox(height: 6),
            Text(
              'Sign in to post a comment.',
              style: TextStyle(fontSize: 13, color: appColors.textMuted),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// More from this course
// TODO(post-detail): replace static list with relatedPostsProvider data
// ─────────────────────────────────────────────────────────────────────────────

class _RelatedPost {
  const _RelatedPost({
    required this.title,
    required this.author,
    required this.type,
  });
  final String title;
  final String author;
  final String type;
}

class _MoreFromThisCourse extends StatelessWidget {
  const _MoreFromThisCourse();

  static const _items = [
    _RelatedPost(title: 'Chapter 7', author: 'Slade', type: 'NOTE'),
    _RelatedPost(title: 'Chapter 6', author: 'Slade', type: 'NOTE'),
    _RelatedPost(title: 'OS vid', author: 'Anonymous', type: 'NOTE'),
    _RelatedPost(title: 'OS Block 2 Notes', author: 'Anonymous', type: 'NOTE'),
    _RelatedPost(title: 'Chapter 10', author: 'Slade', type: 'PAST EXAM'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _SectionLabel(label: 'MORE FROM THIS COURSE'),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: Theme.of(context).dividerColor,
                    ),
                  _RelatedPostTile(item: _items[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RelatedPostTile extends StatelessWidget {
  const _RelatedPostTile({required this.item});
  final _RelatedPost item;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final isPastExam = item.type == 'PAST EXAM';
    final accentColor = isPastExam ? appColors.amber : appColors.info;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 10),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.author} · about 1 month ago',
                  style: TextStyle(fontSize: 12, color: appColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.type,
            style: AppTypography.mono(
              base: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: accentColor,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty comments placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
