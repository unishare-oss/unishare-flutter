// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/post/domain/repositories/comment_repository.dart';

class DeleteComment {
  const DeleteComment(this._repository);
  final CommentRepository _repository;

  Future<void> call(String postId, String commentId) =>
      _repository.deleteComment(postId, commentId);
}
