import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/guest_mode_provider.dart';
import '../../domain/entities/post.dart';
import '../providers/comments_provider.dart';
import '../providers/post_detail_provider.dart';
import '../providers/post_repository_provider.dart';
import '../providers/user_like_status_provider.dart';
import '../widgets/attachment_carousel.dart';
import '../widgets/comment_tile.dart';
import '../widgets/like_button.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFf7f3ee),
      appBar: AppBar(
        backgroundColor: const Color(0xFFf7f3ee),
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1c1917)),
        title: const Text(
          'Post',
          style: TextStyle(
            color: Color(0xFF1c1917),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Color(0xFF8a837e),
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
                  style: const TextStyle(
                    color: Color(0xFF8a837e),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
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

// ---------------------------------------------------------------------------
// Main post body
// ---------------------------------------------------------------------------

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

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: 1 + comments.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _PostHeader(
                  post: post,
                  isLiked: isLiked,
                  isGuest: isGuest,
                  onToggleLike: onToggleLike,
                  commentCount: comments.length,
                );
              }
              return CommentTile(comment: comments[index - 1]);
            },
          ),
        ),
        _CommentInputBar(
          isGuest: isGuest,
          controller: commentController,
          isSubmitting: isSubmitting,
          onSubmit: onSubmitComment,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Post header (everything above the comment list)
// ---------------------------------------------------------------------------

class _PostHeader extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author chip
          _AuthorChip(post: post),
          const SizedBox(height: 16),
          // Title
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1c1917),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          // Body
          Text(
            post.body,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF1c1917),
              height: 1.6,
            ),
          ),
          // Attachment carousel
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            AttachmentCarousel(
              mediaUrls: post.mediaUrls,
              mediaTypes: post.mediaTypes,
            ),
          ],
          const SizedBox(height: 16),
          // Tags
          if (post.tags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: post.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFe2dad0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'FiraCode',
                          fontSize: 11,
                          letterSpacing: 0.55,
                          color: Color(0xFF8a837e),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          // Like button + comment count
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
                size: 20,
                color: const Color(0xFF8a837e),
              ),
              const SizedBox(width: 4),
              Text(
                '$commentCount',
                style: const TextStyle(
                  color: Color(0xFF8a837e),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Divider before comments
          const Divider(color: Color(0xFFe2dad0), height: 1),
          const SizedBox(height: 8),
          Text(
            'Comments',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1c1917),
            ),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatRelativeTime(post.createdAt);
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFe2dad0),
          backgroundImage: post.authorAvatar.isNotEmpty
              ? CachedNetworkImageProvider(post.authorAvatar)
              : null,
          child: post.authorAvatar.isEmpty
              ? Text(
                  post.authorName.isNotEmpty
                      ? post.authorName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1c1917),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1c1917),
                ),
              ),
              Text(
                timeAgo,
                style: const TextStyle(fontSize: 11, color: Color(0xFF8a837e)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
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
  });

  final bool isGuest;
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    if (isGuest) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFffffff),
          border: Border(top: BorderSide(color: Color(0xFFe2dad0))),
        ),
        child: const Text(
          'Sign in to interact',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF8a837e), fontSize: 13),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFffffff),
        border: Border(top: BorderSide(color: Color(0xFFe2dad0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Add a comment…',
                hintStyle: TextStyle(color: Color(0xFF8a837e), fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                filled: true,
                fillColor: Color(0xFFf7f3ee),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                  borderSide: BorderSide(color: Color(0xFFe2dad0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                  borderSide: BorderSide(color: Color(0xFFd97706)),
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSubmit(),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: isSubmitting ? null : onSubmit,
            icon: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  )
                : const Icon(Icons.send_rounded),
            color: const Color(0xFFd97706),
            disabledColor: const Color(0xFF8a837e),
          ),
        ],
      ),
    );
  }
}
