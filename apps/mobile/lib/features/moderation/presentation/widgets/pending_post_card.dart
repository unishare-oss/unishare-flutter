import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/moderation/domain/entities/moderation_verdict.dart';
import 'package:unishare_mobile/features/moderation/domain/entities/pending_post.dart';
import 'package:unishare_mobile/core/firebase/remote_config.dart';
import 'package:unishare_mobile/features/moderation/presentation/widgets/moderation_post_chips.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/attachment_carousel.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class PendingPostCard extends StatelessWidget {
  const PendingPostCard({
    super.key,
    required this.post,
    required this.onApprove,
    required this.onReject,
  });

  final PendingPost post;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final verdict = post.aiVerdict;

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

                // Author name + createdAt
                Text(
                  '${post.authorName} · ${moderationTimeAgo(post.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),

                // Description
                if (post.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    post.description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Tags
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

          // Attachments — full-bleed carousel; tap a slot to preview the file.
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
                // AI verdict section (gated by moderation_ai_advisory flag)
                if (AppFlags.isOn(AppFlags.moderationAiAdvisory)) ...[
                  _AiVerdictSection(verdict: verdict),
                  const SizedBox(height: 12),
                ],

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: onApprove,
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).extension<AppColors>()?.success,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.error,
                          side: BorderSide(color: cs.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiVerdictSection extends StatelessWidget {
  const _AiVerdictSection({required this.verdict});

  final ModerationVerdict? verdict;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = verdict;

    if (v == null) {
      return Text(
        'AI screening in progress...',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final isApprove = v.recommended == 'approve';
    final ac = Theme.of(context).extension<AppColors>();
    final badgeColor = isApprove
        ? (ac?.success ?? Colors.green)
        : theme.colorScheme.error;
    final badgeLabel = isApprove ? 'APPROVE' : 'REJECT';
    final confidencePct = (v.confidence * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeLabel,
                  style: AppTypography.mono(
                    base: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.55,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$confidencePct% confidence',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (v.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(v.reason, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
