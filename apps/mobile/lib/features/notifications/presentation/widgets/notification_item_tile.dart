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
    final hasBody = notification.body.isNotEmpty;
    final relativeTime = _relativeTime(notification.createdAt);

    // Build expanded semantic label for screen readers.
    final semanticParts = <String>[
      notification.actorName,
      actionText,
      notification.targetTitle,
      if (hasBody) notification.body,
      relativeTime,
      isUnread ? 'Unread' : 'Read',
    ];
    final semanticLabel = semanticParts.join('. ');

    // Content widget — laid out first so the Stack can size itself to it.
    final content = Container(
      color: isUnread ? ac.amberSubtle.withValues(alpha: 0.35) : null,
      padding: const EdgeInsets.only(left: 3), // reserve bar space
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: ' $actionText'),
                      ],
                    ),
                  ),
                  // Body excerpt — rendered below actor/action when present
                  if (hasBody) ...[
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ac.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
                    relativeTime,
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
    );

    return Semantics(
      label: semanticLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Main content (drives the Stack's size).
            content,

            // Unread indicator bar — Positioned to stretch full height of Stack.
            if (isUnread)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: ac.amber,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                  ),
                ),
              ),
          ],
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
        return 'accepted your suggestion';
      case NotificationType.badgeUnlock:
        return 'awarded you a new badge';
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
