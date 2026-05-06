// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';

class WatchPost {
  const WatchPost(this._repository);
  final PostRepository _repository;

  Stream<Post> call(String postId) => _repository.watchPost(postId);
}
