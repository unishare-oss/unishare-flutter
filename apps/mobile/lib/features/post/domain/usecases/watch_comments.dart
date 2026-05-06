// Pure Dart — zero Flutter or Firebase imports.

import '../entities/comment.dart';
import '../repositories/comment_repository.dart';

class WatchComments {
  const WatchComments(this._repository);
  final CommentRepository _repository;

  Stream<List<Comment>> call(String postId) =>
      _repository.watchComments(postId);
}
