import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/moderation/domain/entities/moderation_verdict.dart';
import 'package:unishare_mobile/features/moderation/domain/entities/pending_post.dart';
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
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                _PostTypeChip(postType: post.postType),
              ],
            ),
            const SizedBox(height: 4),

            // Author name + createdAt
            Text(
              '${post.authorName} · ${_timeAgo(post.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            if (post.description.isNotEmpty) ...[
              Text(
                post.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],

            // Tags
            if (post.tags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: post.tags.map((tag) => _TagChip(tag: tag)).toList(),
              ),
              const SizedBox(height: 10),
            ],

            // AI verdict section
            _AiVerdictSection(verdict: verdict),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onApprove,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
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
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade600),
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
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours} hours ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes} min ago';
    return 'just now';
  }
}

class _PostTypeChip extends StatelessWidget {
  const _PostTypeChip({required this.postType});

  final String postType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        postType.toUpperCase(),
        style: AppTypography.mono(
          base: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            letterSpacing: 0.55,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag,
        style: AppTypography.mono(
          base: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            letterSpacing: 0.55,
          ),
        ),
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
    final badgeColor = isApprove ? Colors.green.shade600 : Colors.red.shade600;
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
