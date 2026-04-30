import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/post_feed_provider.dart';
import '../widgets/post_card.dart';

class PostFeedScreen extends ConsumerStatefulWidget {
  const PostFeedScreen({super.key});

  @override
  ConsumerState<PostFeedScreen> createState() => _PostFeedScreenState();
}

class _PostFeedScreenState extends ConsumerState<PostFeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(postFeedNotifierProvider.notifier)
          .fetchNextPage()
          .catchError((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't load more posts")),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(postFeedNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load feed',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(postFeedNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (feedState) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(postFeedNotifierProvider),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: feedState.posts.length + 1,
            itemBuilder: (context, index) {
              if (index < feedState.posts.length) {
                return PostCard(
                  post: feedState.posts[index],
                  currentUserId: null, // TODO: wire up auth provider
                );
              }
              if (feedState.isFetchingMore) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (!feedState.hasMore) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text("You're all caught up")),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
