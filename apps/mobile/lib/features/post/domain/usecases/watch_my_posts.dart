// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';

class WatchMyPosts {
  const WatchMyPosts(this._repository);
  final PostRepository _repository;

  Stream<List<Post>> call(String authorId) =>
      _repository.watchPostsByAuthor(authorId);
}
