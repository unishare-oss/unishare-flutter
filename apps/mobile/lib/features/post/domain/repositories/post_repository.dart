// Pure Dart — zero Flutter or Firebase imports.

import 'dart:typed_data';

import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';

abstract interface class PostRepository {
  Stream<List<Post>> watchFeed({int limit = 20});
  Stream<Post> watchPost(String postId);
  Stream<List<Post>> watchPostsByAuthor(String authorId, {int limit = 50});

  /// Unbounded count of posts by [authorId] using a Firestore aggregation.
  /// Cheap (no doc fetch) and reflects the true total — unlike
  /// `watchPostsByAuthor(...).length` which is capped by the page limit.
  Future<int> countPostsByAuthor(String authorId);

  Future<void> incrementViewCount(String postId);

  Future<void> saveDraft(PostDraft draft);
  Future<void> removeDraft(String draftId);
  Future<List<PostDraft>> loadDraftQueue();
  Future<void> publishDraft(
    PostDraft draft, {
    void Function(double progress)? onProgress,
    void Function(int fileIndex, double fileProgress)? onFileProgress,
    void Function(PostDraft)? onDraftUpdated,
    Map<String, Uint8List>? fileDataOverride,
    CancellationToken? cancellationToken,
  });

  // SPEC-0011
  Future<void> deletePost(String postId);
  Future<void> updatePost({
    required String postId,
    required String title,
    required String description,
    required List<String> tags,
    String? externalUrl,
    required String moduleNumber,
    required bool descriptionChanged,
    required bool titleChanged,
    required SummaryStatus? currentSummaryStatus,
  });
}
