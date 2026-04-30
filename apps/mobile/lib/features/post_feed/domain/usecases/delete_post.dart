import '../repositories/post_repository.dart';

class DeletePost {
  const DeletePost(this._repository);

  final PostRepository _repository;

  Future<void> call(String postId) {
    return _repository.deletePost(postId);
  }
}
