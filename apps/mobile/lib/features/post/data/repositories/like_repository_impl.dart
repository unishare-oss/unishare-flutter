// TODO(flutter-engineer): implement per SPEC-0006

import '../../domain/repositories/like_repository.dart';

class LikeRepositoryImpl implements LikeRepository {
  // Inject FirebaseFirestore and FirebaseAuth at construction time.
  // Do NOT access Firebase singletons directly here — pass via constructor
  // so the repository remains testable.

  @override
  Future<void> toggleLike(String postId) {
    throw UnimplementedError('TODO(flutter-engineer): implement per SPEC-0006');
  }

  @override
  Stream<bool> watchLikeStatus(String postId) {
    throw UnimplementedError('TODO(flutter-engineer): implement per SPEC-0006');
  }
}
