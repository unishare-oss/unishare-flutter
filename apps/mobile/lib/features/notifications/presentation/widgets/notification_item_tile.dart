import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/notifications/domain/entities/notification_item.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class NotificationItemTile extends StatelessWidget {
  const NotificationItemTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final cs = theme.colorScheme;

    final isUnread = !notification.isRead;
    final actionText = _actionText(notification.type);

    return Semantics(
      label: '${notification.title}. ${isUnread ? 'Unread' : 'Read'}',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: isUnread ? ac.amberSubtle.withValues(alpha: 0.35) : null,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Unread indicator bar
                if (isUnread)
                  Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: ac.amber,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 3),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Unread dot indicator
                        if (isUnread)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, right: 8),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: ac.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Actor name + action
                              RichText(
                                text: TextSpan(
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurface,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: notification.actorName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(text: ' $actionText'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Target title
                              Text(
                                notification.targetTitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: ac.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Relative timestamp
                              Text(
                                _relativeTime(notification.createdAt),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: ac.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _actionText(NotificationType type) {
    switch (type) {
      case NotificationType.postCommentAdded:
        return 'commented on your post';
      case NotificationType.postLiked:
        return 'liked your post';
      case NotificationType.commentReply:
        return 'replied to your comment';
      case NotificationType.requestUpvoted:
        return 'upvoted your request';
      case NotificationType.suggestionSubmitted:
        return 'suggested a post for your request';
      case NotificationType.suggestionAccepted:
        return 'your suggestion was accepted';
    }
  }

  String _relativeTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
