// TODO(flutter-engineer): implement per SPEC-0006

import '../repositories/like_repository.dart';

class ToggleLike {
  const ToggleLike(this._repository);
  final LikeRepository _repository;

  Future<void> call(String postId) => _repository.toggleLike(postId);
}
