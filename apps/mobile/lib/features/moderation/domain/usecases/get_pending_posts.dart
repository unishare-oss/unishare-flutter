// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/moderation/domain/entities/pending_post.dart';
import 'package:unishare_mobile/features/moderation/domain/repositories/moderation_repository.dart';

class GetPendingPosts {
  const GetPendingPosts(this._repository);

  final ModerationRepository _repository;

  Stream<List<PendingPost>> call() => _repository.getPendingPosts();
}
