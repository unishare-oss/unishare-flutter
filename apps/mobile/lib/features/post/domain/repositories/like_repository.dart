// Pure Dart — zero Flutter or Firebase imports.

abstract interface class LikeRepository {
  /// Creates posts/{postId}/likes/{currentUserId} if absent (like),
  /// or deletes it if present (unlike).
  Future<void> toggleLike(String postId);

  /// Emits true when posts/{postId}/likes/{currentUserId} exists.
  /// Emits false if there is no authenticated user.
  Stream<bool> watchLikeStatus(String postId);
}
