import '../repositories/post_repository.dart';

class ToggleLike {
  const ToggleLike(this._repository);

  final PostRepository _repository;

  Future<void> call(String postId, {required bool liked}) {
    return _repository.toggleLike(postId, liked: liked);
  }
}
