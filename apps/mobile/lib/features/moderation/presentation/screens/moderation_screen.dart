import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/moderation/presentation/providers/moderation_action_provider.dart';
import 'package:unishare_mobile/features/moderation/presentation/providers/moderation_queue_provider.dart';
import 'package:unishare_mobile/features/moderation/presentation/widgets/pending_post_card.dart';
import 'package:unishare_mobile/features/moderation/presentation/widgets/rejected_post_card.dart';
import 'package:unishare_mobile/shared/widgets/main_nav_bar.dart';

class ModerationScreen extends StatelessWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Moderation'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: const TabBarView(children: [_PendingTab(), _RejectedTab()]),
      ),
    );
  }
}

class _PendingTab extends ConsumerWidget {
  const _PendingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(moderationQueueProvider);

    return queueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        key: const Key('moderation-error'),
        child: Text('Error: $error', textAlign: TextAlign.center),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(child: Text('No pending posts'));
        }
        return ListView.separated(
          padding: const EdgeInsets.only(
            top: 8,
            bottom: MainNavBar.bottomInset,
          ),
          itemCount: posts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 2),
          itemBuilder: (context, index) {
            final post = posts[index];
            return PendingPostCard(
              post: post,
              onApprove: () => _handleApprove(context, ref, post.id),
              onReject: () => _handleReject(context, ref, post.id),
            );
          },
        );
      },
    );
  }

  Future<void> _handleApprove(
    BuildContext context,
    WidgetRef ref,
    String postId,
  ) async {
    await ref.read(moderationActionProvider.notifier).approve(postId);
    if (!context.mounted) return;
    final state = ref.read(moderationActionProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      state is AsyncError
          ? SnackBar(content: Text('Failed: ${state.error}'))
          : const SnackBar(content: Text('Post approved')),
    );
  }

  Future<void> _handleReject(
    BuildContext context,
    WidgetRef ref,
    String postId,
  ) async {
    final reason = await _showRejectDialog(context);
    if (reason == null) return;
    await ref.read(moderationActionProvider.notifier).reject(postId, reason);
    if (!context.mounted) return;
    final state = ref.read(moderationActionProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      state is AsyncError
          ? SnackBar(content: Text('Failed: ${state.error}'))
          : const SnackBar(content: Text('Post rejected')),
    );
  }

  Future<String?> _showRejectDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Post'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter reason for rejection',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 4,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final reason = controller.text.trim();
                if (reason.isNotEmpty) {
                  Navigator.of(context).pop(reason);
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }
}

class _RejectedTab extends ConsumerWidget {
  const _RejectedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rejectedAsync = ref.watch(moderationRejectedQueueProvider);

    return rejectedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        key: const Key('moderation-rejected-error'),
        child: Text('Error: $error', textAlign: TextAlign.center),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(child: Text('No rejected posts'));
        }
        return ListView.separated(
          padding: const EdgeInsets.only(
            top: 8,
            bottom: MainNavBar.bottomInset,
          ),
          itemCount: posts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 2),
          itemBuilder: (context, index) {
            final post = posts[index];
            return RejectedPostCard(
              post: post,
              onRestore: () => _handleRestore(context, ref, post.id),
            );
          },
        );
      },
    );
  }

  Future<void> _handleRestore(
    BuildContext context,
    WidgetRef ref,
    String postId,
  ) async {
    await ref.read(moderationActionProvider.notifier).restore(postId);
    if (!context.mounted) return;
    final state = ref.read(moderationActionProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      state is AsyncError
          ? SnackBar(content: Text('Failed: ${state.error}'))
          : const SnackBar(content: Text('Post restored to queue')),
    );
  }
}
