import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/saved/domain/entities/saved_post.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/saved_post_repository_provider.dart';
import 'package:unishare_mobile/features/saved/presentation/widgets/save_button.dart';

class SavedPostCard extends ConsumerWidget {
  const SavedPostCard({super.key, required this.savedPost, this.onTap});

  final SavedPost savedPost;
  final VoidCallback? onTap;

  static const _amber = Color(0xFFD97706);
  static const _muted = Color(0xFF8a837e);
  static const _border = Color(0xFFe2dad0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = savedPost.snapshot;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: type badge + course code + bookmark toggle
            Row(
              children: [
                _TypeBadge(postType: snapshot.postType),
                const SizedBox(width: 8),
                Text(
                  snapshot.courseId,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                SaveButton(
                  isSaved: true,
                  onTap: () {
                    ref
                        .read(savedPostRepositoryProvider)
                        .unsavePost(savedPost.postId);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              snapshot.title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1c1917),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Author row
            Row(
              children: [
                _AuthorAvatar(name: snapshot.authorName),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    snapshot.authorName.isEmpty
                        ? 'Anonymous'
                        : snapshot.authorName,
                    style: theme.textTheme.bodySmall?.copyWith(color: _muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Comments + relative time
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 13, color: _muted),
                const SizedBox(width: 4),
                Text(
                  '${snapshot.commentsCount} comments · ${_relativeTime(savedPost.savedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: _muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()} years ago';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()} months ago';
    if (diff.inDays >= 1) return '${diff.inDays} days ago';
    if (diff.inHours >= 1) return '${diff.inHours} hours ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes} minutes ago';
    return 'just now';
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.postType});
  final String postType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1c1917)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        postType.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1c1917),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.name});
  final String name;

  String get _initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 10,
      backgroundColor: const Color(0xFFe2dad0),
      child: Text(
        _initials,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1c1917),
        ),
      ),
    );
  }
}
