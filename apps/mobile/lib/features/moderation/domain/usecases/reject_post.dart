// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/moderation/domain/repositories/moderation_repository.dart';

class RejectPost {
  const RejectPost(this._repository);

  final ModerationRepository _repository;

  Future<void> call(String postId, String reason) {
    if (postId.isEmpty) throw ArgumentError('postId must not be empty');
    if (reason.trim().isEmpty) {
      throw ArgumentError('reason must not be blank');
    }
    return _repository.rejectPost(postId, reason);
  }
}
