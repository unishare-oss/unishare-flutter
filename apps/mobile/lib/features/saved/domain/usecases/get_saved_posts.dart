// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/saved/domain/entities/saved_post.dart';
import 'package:unishare_mobile/features/saved/domain/repositories/saved_post_repository.dart';

class GetSavedPosts {
  const GetSavedPosts(this._repository);
  final SavedPostRepository _repository;

  Stream<List<SavedPost>> call() => _repository.watchSavedPosts();
}
