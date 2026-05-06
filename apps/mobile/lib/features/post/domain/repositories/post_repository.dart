// Pure Dart — zero Flutter or Firebase imports.

import 'dart:typed_data';

import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';

abstract interface class PostRepository {
  // Existing — must not be removed or renamed.
  Stream<List<Post>> watchFeed({int limit = 20});
  Future<void> saveDraft(PostDraft draft);
  Future<void> removeDraft(String draftId);
  Future<List<PostDraft>> loadDraftQueue();
  Future<void> publishDraft(
    PostDraft draft, {
    void Function(double progress)? onProgress,
    // Web uploads: maps localMediaPaths key → file bytes (path is null on web)
    Map<String, Uint8List>? fileDataOverride,
  });

  // Added for SPEC-0006.
  Stream<Post> watchPost(String postId);
}
