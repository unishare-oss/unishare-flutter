import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../post/domain/entities/post.dart';

/// Minimal post card for the feed.
///
/// Shows title, author name, and like count. Taps navigate to the
/// Post Detail screen with the post as seed data for instant render.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/posts/${post.id}', extra: post),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFffffff),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFe2dad0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author name
            Text(
              post.authorName,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8a837e),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            // Title
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1c1917),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            // Like count
            Row(
              children: [
                const Icon(
                  Icons.favorite_border,
                  size: 16,
                  color: Color(0xFF8a837e),
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.likesCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8a837e),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
