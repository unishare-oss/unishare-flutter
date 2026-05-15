import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:unishare_mobile/features/notifications/presentation/providers/notification_repository_provider.dart';
import 'package:unishare_mobile/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:unishare_mobile/features/notifications/presentation/widgets/notification_item_tile.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/widgets/scroll_to_top_target.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({required GlobalKey<State> scrollKey})
    : super(key: scrollKey);

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with ScrollToTopTarget {
  final ScrollController _scrollController = ScrollController();

  @override
  ScrollController get scrollController => _scrollController;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;

    final asyncNotifs = ref.watch(watchNotificationsProvider);
    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.asData?.value;

    // Determine whether "Mark all read" should be shown.
    final hasUnread = asyncNotifs.asData?.value.any((n) => !n.isRead) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (hasUnread && user != null)
            TextButton(
              onPressed: () async {
                await ref
                    .read(markAllNotificationsReadUseCaseProvider)
                    .call(user.id);
              },
              child: Text('Mark all read', style: TextStyle(color: ac.amber)),
            ),
        ],
      ),
      body: asyncNotifs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Text(
            'Could not load notifications',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        data: (notifications) {
          // Guest / unauthenticated — show sign-in prompt.
          if (user == null) {
            return _SignInPrompt(onSignIn: () => context.push('/welcome'));
          }

          // Empty state.
          if (notifications.isEmpty) {
            return _EmptyState(ac: ac, theme: theme);
          }

          // Notification list.
          return ListView.separated(
            controller: _scrollController,
            itemCount: notifications.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, thickness: 1, color: theme.dividerColor),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return NotificationItemTile(
                notification: notif,
                onTap: () async {
                  // Mark as read first.
                  if (!notif.isRead) {
                    await ref
                        .read(markNotificationReadUseCaseProvider)
                        .call(user.id, notif.id);
                  }
                  // Navigate based on targetType.
                  if (!context.mounted) return;
                  final destination = notif.targetType == 'request'
                      ? '/more/requests/${notif.targetId}'
                      : '/posts/${notif.targetId}';
                  context.push(destination);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.ac, required this.theme});

  final AppColors ac;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 56,
            color: ac.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: ac.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Activity on your posts and requests will appear here.',
            style: theme.textTheme.bodySmall?.copyWith(color: ac.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 56, color: ac.textMuted),
            const SizedBox(height: 16),
            Text(
              'Sign in to see your notifications',
              style: theme.textTheme.titleMedium?.copyWith(
                color: ac.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ac.amber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: onSignIn,
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
