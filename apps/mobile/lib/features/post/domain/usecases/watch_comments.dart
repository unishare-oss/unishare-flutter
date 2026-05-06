// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/post/domain/entities/comment.dart';
import 'package:unishare_mobile/features/post/domain/repositories/comment_repository.dart';

class WatchComments {
  const WatchComments(this._repository);
  final CommentRepository _repository;

  Stream<List<Comment>> call(String postId) =>
      _repository.watchComments(postId);
}
