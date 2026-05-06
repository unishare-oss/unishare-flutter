// TODO(flutter-engineer): implement per SPEC-0006

abstract interface class LikeRepository {
  /// Creates posts/{postId}/likes/{currentUserId} if absent (like),
  /// or deletes it if present (unlike).
  /// likesCount on the post document is maintained by Cloud Function.
  Future<void> toggleLike(String postId);

  /// Emits true when posts/{postId}/likes/{currentUserId} exists.
  /// Emits false when absent or when the current user is a guest.
  Stream<bool> watchLikeStatus(String postId);
}
