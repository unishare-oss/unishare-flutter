// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/saved/domain/repositories/saved_post_repository.dart';

class UnsavePost {
  const UnsavePost(this._repository);
  final SavedPostRepository _repository;

  Future<void> call(String postId) => _repository.unsavePost(postId);
}
