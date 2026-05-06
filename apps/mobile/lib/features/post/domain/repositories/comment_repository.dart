// TODO(flutter-engineer): implement per SPEC-0006

import '../entities/comment.dart';

abstract interface class CommentRepository {
  /// Emits the full ordered comment list and re-emits on any change.
  /// Ordered by createdAt ascending. Flat list — no threading in v1.
  Stream<List<Comment>> watchComments(String postId);

  /// Writes a new comment to posts/{postId}/comments.
  /// [body] must be trimmed and non-empty; AddComment use case enforces this.
  Future<void> addComment(String postId, String body);
}
