// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/post/domain/entities/comment.dart';

abstract interface class CommentRepository {
  /// Emits the full ordered comment list and re-emits on any change.
  /// Ordered by createdAt ascending. Flat list — no threading in v1.
  Stream<List<Comment>> watchComments(String postId);

  /// Writes a new comment document to posts/{postId}/comments.
  /// [body] must be trimmed and non-empty; the use case enforces this.
  /// Sets authorId, authorName, authorAvatar from the current Firebase Auth user.
  /// [parentId] non-null for replies; null for top-level comments.
  Future<void> addComment(String postId, String body, {String? parentId});
}
