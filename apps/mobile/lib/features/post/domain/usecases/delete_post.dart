// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';

class DeletePost {
  const DeletePost(this._repository);
  final PostRepository _repository;

  Future<void> call(String postId) => _repository.deletePost(postId);
}
