// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/saved/domain/entities/saved_post_snapshot.dart';
import 'package:unishare_mobile/features/saved/domain/repositories/saved_post_repository.dart';

class SavePost {
  const SavePost(this._repository);
  final SavedPostRepository _repository;

  /// Throws [ArgumentError] if [postId] is empty after trimming.
  Future<void> call(String postId, SavedPostSnapshot snapshot) {
    if (postId.trim().isEmpty) {
      throw ArgumentError.value(postId, 'postId', 'postId must not be empty');
    }
    return _repository.savePost(postId.trim(), snapshot);
  }
}
