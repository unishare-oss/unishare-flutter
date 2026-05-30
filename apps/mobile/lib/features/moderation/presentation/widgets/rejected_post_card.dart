import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/moderation/domain/entities/pending_post.dart';
import 'package:unishare_mobile/features/moderation/presentation/widgets/moderation_post_chips.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/attachment_carousel.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

/// Card for a previously-rejected post in the moderation screen's Rejected
/// tab. Surfaces the rejection reason and offers a Restore action that sends
/// the post back to the pending queue for re-review.
class RejectedPostCard extends StatelessWidget {
  const RejectedPostCard({
    super.key,
    required this.post,
    required this.onRestore,
  });

  final PendingPost post;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final rejectedAt = post.moderatedAt;
    final subtitle = rejectedAt != null
        ? '${post.authorName} · rejected ${moderationTimeAgo(rejectedAt)}'
        : post.authorName;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + post type chip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        post.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ModerationTypeChip(postType: post.postType),
                  ],
                ),
                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),

                if (post.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    post.description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: post.tags
                        .map((tag) => ModerationTagChip(tag: tag))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),

          // Attachments — full-bleed carousel; tap a slot to preview.
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            AttachmentCarousel(
              mediaUrls: post.mediaUrls,
              mediaTypes: post.mediaTypes,
            ),
          ],

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RejectionReason(reason: post.rejectionReason),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: onRestore,
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text('Restore to queue'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectionReason extends StatelessWidget {
  const _RejectionReason({required this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = (reason ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REJECTED',
            style: AppTypography.mono(
              base: theme.textTheme.labelSmall?.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.55,
              ),
            ),
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(text, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
