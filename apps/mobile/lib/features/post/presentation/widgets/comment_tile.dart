import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/features/post/domain/entities/comment.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({super.key, required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(url: comment.authorAvatar, name: comment.authorName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(comment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: appColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.body,
                  style: TextStyle(
                    fontSize: 14,
                    color: scheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    // Older than 1 week → show full date
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name});

  final String url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;

    if (url.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: CachedNetworkImageProvider(url),
        backgroundColor: appColors.muted,
      );
    }
    // Fallback: initials
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 18,
      backgroundColor: appColors.muted,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
