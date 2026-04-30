import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/post.dart';
import '../providers/post_feed_provider.dart';
import 'like_button.dart';

class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post, required this.currentUserId});

  final Post post;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => context.push('/feed/posts/${post.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AuthorRow(post: post),
              const SizedBox(height: 12),
              Text(
                post.title,
                style: theme.textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (post.body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  post.body,
                  style: theme.textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (post.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                _TagChips(tags: post.tags),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  LikeButton(
                    liked: post.isLikedByCurrentUser,
                    count: post.likesCount,
                    onTap: () {
                      ref
                          .read(postFeedNotifierProvider.notifier)
                          .toggleLike(post.id, liked: !post.isLikedByCurrentUser)
                          .catchError((_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not update like — try again'),
                            ),
                          );
                        }
                      });
                    },
                  ),
                  const Spacer(),
                  if (currentUserId != null && post.authorId == currentUserId)
                    _DeleteMenu(
                      onDelete: () {
                        ref
                            .read(postFeedNotifierProvider.notifier)
                            .deletePost(post.id)
                            .catchError((_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not delete post — try again'),
                              ),
                            );
                          }
                        });
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: post.authorAvatar.isNotEmpty
              ? CachedNetworkImageProvider(post.authorAvatar)
              : null,
          child: post.authorAvatar.isEmpty
              ? Text(
                  post.authorName.isNotEmpty
                      ? post.authorName[0].toUpperCase()
                      : '?',
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
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _relativeTime(post.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _TagChips extends StatelessWidget {
  const _TagChips({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags
          .map(
            (tag) => Chip(
              label: Text(tag),
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
              backgroundColor: Colors.transparent,
              labelStyle: Theme.of(context).textTheme.bodySmall,
            ),
          )
          .toList(),
    );
  }
}

class _DeleteMenu extends StatelessWidget {
  const _DeleteMenu({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (value) {
        if (value == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete post'),
        ),
      ],
    );
  }
}
