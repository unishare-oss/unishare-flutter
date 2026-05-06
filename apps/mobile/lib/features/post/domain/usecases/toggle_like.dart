// Pure Dart — zero Flutter or Firebase imports.

import '../repositories/like_repository.dart';

/// Checks posts/{postId}/likes/{userId}:
///   absent  → creates the document (like)
///   present → deletes the document (unlike)
/// likesCount on the post document is maintained by a Cloud Function;
/// the client never writes it directly.
class ToggleLike {
  const ToggleLike(this._repository);
  final LikeRepository _repository;

  Future<void> call(String postId) => _repository.toggleLike(postId);
}
