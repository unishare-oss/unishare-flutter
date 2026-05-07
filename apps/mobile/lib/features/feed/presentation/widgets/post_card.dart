import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post_snapshot.dart';
import 'package:unishare_mobile/features/saved/domain/usecases/save_post.dart';
import 'package:unishare_mobile/features/saved/domain/usecases/unsave_post.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/is_post_saved_provider.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/saved_post_repository_provider.dart';
import 'package:unishare_mobile/features/saved/presentation/widgets/save_button.dart';

class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSavedAsync = ref.watch(isPostSavedProvider(post.id));
    final isSaved = isSavedAsync.asData?.value ?? false;

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
            // Header row: author name + bookmark toggle (top-right)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    post.authorName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8a837e),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SaveButton(
                  isSaved: isSaved,
                  onTap: () => _toggleSave(ref, isSaved),
                ),
              ],
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

  void _toggleSave(WidgetRef ref, bool currentlySaved) {
    final repository = ref.read(savedPostRepositoryProvider);
    if (currentlySaved) {
      UnsavePost(repository).call(post.id);
    } else {
      SavePost(repository).call(
        post.id,
        SavedPostSnapshot(
          title: post.title,
          authorName: post.authorName,
          authorAvatar: post.authorAvatar,
          courseId: post.courseId,
          postType: post.postType.name,
          tags: post.tags,
          commentsCount: 0,
        ),
      );
    }
  }
}
