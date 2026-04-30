import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/post.dart';
import '../providers/post_feed_provider.dart';
import '../widgets/like_button.dart';

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postDetailProvider(postId));

    return Scaffold(
      appBar: AppBar(),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Post not found',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
        data: (post) => _PostBody(post: post),
      ),
    );
  }
}

class _PostBody extends ConsumerWidget {
  const _PostBody({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
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
              const SizedBox(width: 12),
              Text(post.authorName, style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 20),
          Text(post.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(post.body, style: theme.textTheme.bodyMedium),
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...post.mediaUrls.map(
              (url) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
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
          const SizedBox(height: 32),
          Text(
            'Comments',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Comments coming soon.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
