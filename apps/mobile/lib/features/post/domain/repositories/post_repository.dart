// TODO(flutter-engineer): implement per SPEC-0004 API contracts
// Check for a pre-existing file from PROP-0003 before finalising — do not break watchFeed.

import '../entities/post.dart';
import '../entities/post_draft.dart';

abstract interface class PostRepository {
  Stream<List<Post>> watchFeed({int limit = 20});

  Future<void> saveDraft(PostDraft draft);
  Future<void> removeDraft(String draftId);
  Future<List<PostDraft>> loadDraftQueue();
  Future<void> publishDraft(
    PostDraft draft, {
    void Function(double progress)? onProgress,
  });
}
