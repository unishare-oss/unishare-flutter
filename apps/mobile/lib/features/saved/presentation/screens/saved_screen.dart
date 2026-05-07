import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/saved_posts_provider.dart';
import 'package:unishare_mobile/features/saved/presentation/widgets/saved_post_card.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedPostsProvider);
    final isGuest = ref.watch(guestModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          if (isGuest) const _GuestBanner(),
          Expanded(
            child: savedAsync.when(
              loading: () => const _SkeletonList(),
              error: (e, _) => _ErrorState(
                onRetry: () => ref.invalidate(savedPostsProvider),
              ),
              data: (posts) {
                if (posts.isEmpty) return const _EmptyState();
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, i) => SavedPostCard(
                    savedPost: posts[i],
                    onTap: () => context.push('/posts/${posts[i].postId}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Saved posts are stored locally and won't sync across devices.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          TextButton(
            onPressed: () => context.go('/welcome'),
            child: const Text('→ Sign in to sync'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No saved posts yet.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFF8a837e)),
          const SizedBox(height: 12),
          const Text('Something went wrong'),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFf5f4f2),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
