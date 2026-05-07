// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/saved/domain/repositories/saved_post_repository.dart';

class IsPostSaved {
  const IsPostSaved(this._repository);
  final SavedPostRepository _repository;

  Stream<bool> call(String postId) => _repository.isPostSaved(postId);
}
