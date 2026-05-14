import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';
import 'package:unishare_mobile/features/post/domain/entities/comment.dart';

class CommentTile extends StatefulWidget {
  const CommentTile({
    super.key,
    required this.comment,
    this.replies = const [],
    this.currentUid,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onDeleteReply,
  });

  final Comment comment;
  final List<Comment> replies;

  /// UID of the signed-in user — used to show delete on owned replies.
  final String? currentUid;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final void Function(String replyId)? onDeleteReply;

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool _repliesExpanded = true;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final hasReplies = widget.replies.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentRow(
            comment: widget.comment,
            isReply: false,
            onReply: widget.onReply,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
          ),
          if (hasReplies) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _repliesExpanded = !_repliesExpanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _repliesExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: ac.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _repliesExpanded ? 'HIDE REPLIES' : 'SHOW REPLIES',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ac.textMuted,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (hasReplies && _repliesExpanded) ...[
            for (final reply in widget.replies) ...[
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: ac.amber,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CommentRow(
                        comment: reply,
                        isReply: true,
                        onDelete:
                            (widget.onDeleteReply != null &&
                                widget.currentUid == reply.authorId)
                            ? () => widget.onDeleteReply!(reply.id)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: Theme.of(context).dividerColor),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.comment,
    required this.isReply,
    this.onReply,
    this.onEdit,
    this.onDelete,
  });

  final Comment comment;
  final bool isReply;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(
          url: comment.authorAvatar,
          name: comment.authorName,
          size: isReply ? 28 : 32,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.authorName,
                    style: isReply
                        ? AppTypography.mono(
                            base: theme.textTheme.bodySmall?.copyWith(
                              color: ac.amber,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatTimestamp(comment.createdAt),
                    style: isReply
                        ? AppTypography.mono(
                            base: theme.textTheme.labelSmall?.copyWith(
                              color: ac.textMuted,
                            ),
                          )
                        : theme.textTheme.labelSmall?.copyWith(
                            color: ac.textMuted,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                comment.body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  // Parent: REPLY then DELETE side by side
                  if (!isReply && onReply != null)
                    _ActionButton(
                      icon: Icons.reply,
                      label: 'REPLY',
                      onTap: onReply!,
                      color: ac.textMuted,
                    ),
                  if (!isReply && onDelete != null) ...[
                    const SizedBox(width: 14),
                    _IconAction(
                      icon: Icons.delete_outline,
                      onTap: onDelete!,
                      color: ac.textMuted,
                    ),
                  ],
                  // Child: DELETE replaces REPLY
                  if (isReply && onDelete != null)
                    _IconAction(
                      icon: Icons.delete_outline,
                      onTap: onDelete!,
                      color: ac.textMuted,
                    ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 14),
                    _IconAction(
                      icon: Icons.edit_outlined,
                      onTap: onEdit!,
                      color: ac.textMuted,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'less than a minute ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return '1 day ago';
    if (diff.inDays < 30) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 15, color: color),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name, required this.size});

  final String url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, _) => _placeholder(context, size, cs),
          errorWidget: (context, url, _) => _placeholder(context, size, cs),
        ),
      );
    }
    return _placeholder(context, size, cs);
  }

  Widget _placeholder(BuildContext context, double size, ColorScheme cs) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.45,
        ),
      ),
    );
  }
}
