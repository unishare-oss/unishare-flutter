// Pure Dart — zero Flutter or Firebase imports.

import 'dart:typed_data';

import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';

abstract interface class PostRepository {
  Stream<List<Post>> watchFeed({int limit = 20});
  Stream<Post> watchPost(String postId);
  Future<void> saveDraft(PostDraft draft);
  Future<void> removeDraft(String draftId);
  Future<List<PostDraft>> loadDraftQueue();
  Future<void> publishDraft(
    PostDraft draft, {
    void Function(double progress)? onProgress,
    void Function(int fileIndex, double fileProgress)? onFileProgress,
    Map<String, Uint8List>? fileDataOverride,
    CancellationToken? cancellationToken,
  });
}
