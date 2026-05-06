// TODO(flutter-engineer): implement per SPEC-0006

import '../entities/comment.dart';
import '../repositories/comment_repository.dart';

class WatchComments {
  const WatchComments(this._repository);
  final CommentRepository _repository;

  Stream<List<Comment>> call(String postId) =>
      _repository.watchComments(postId);
}
