// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/post/domain/repositories/comment_repository.dart';

class AddComment {
  const AddComment(this._repository);
  final CommentRepository _repository;

  /// Throws [ArgumentError] if body is blank after trimming.
  Future<void> call(String postId, String body, {String? parentId}) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(body, 'body', 'Comment body must not be blank');
    }
    return _repository.addComment(postId, trimmed, parentId: parentId);
  }
}
