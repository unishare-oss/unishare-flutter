// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/moderation/domain/repositories/moderation_repository.dart';

class ApprovePost {
  const ApprovePost(this._repository);

  final ModerationRepository _repository;

  Future<void> call(String postId) {
    if (postId.isEmpty) throw ArgumentError('postId must not be empty');
    return _repository.approvePost(postId);
  }
}
