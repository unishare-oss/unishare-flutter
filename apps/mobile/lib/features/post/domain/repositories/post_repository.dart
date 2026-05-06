// Pure Dart — zero Flutter or Firebase imports.

import '../entities/post.dart';
import '../entities/post_draft.dart';

abstract interface class PostRepository {
  // Existing — must not be removed or renamed.
  Stream<List<Post>> watchFeed({int limit = 20});
  Future<void> saveDraft(PostDraft draft);
  Future<void> removeDraft(String draftId);
  Future<List<PostDraft>> loadDraftQueue();
  Future<void> publishDraft(
    PostDraft draft, {
    void Function(double progress)? onProgress,
  });

  // Added for SPEC-0006.
  Stream<Post> watchPost(String postId);
}
