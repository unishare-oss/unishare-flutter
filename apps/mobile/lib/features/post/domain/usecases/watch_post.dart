// Pure Dart — zero Flutter or Firebase imports.

import '../entities/post.dart';
import '../repositories/post_repository.dart';

class WatchPost {
  const WatchPost(this._repository);
  final PostRepository _repository;

  Stream<Post> call(String postId) => _repository.watchPost(postId);
}
