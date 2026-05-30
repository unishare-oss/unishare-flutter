// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/moderation/domain/entities/pending_post.dart';

abstract interface class ModerationRepository {
  Stream<List<PendingPost>> getPendingPosts();
  Stream<List<PendingPost>> getRejectedPosts();
  Future<void> approvePost(String postId);
  Future<void> rejectPost(String postId, String reason);

  /// Reverses a rejection: moves the post back to the pending queue.
  Future<void> restorePost(String postId);
}
