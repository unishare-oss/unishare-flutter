// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/requests/domain/repositories/request_repository.dart';

class SuggestFulfillment {
  const SuggestFulfillment(this._repository);
  final RequestRepository _repository;

  Future<void> call({
    required String requestId,
    required String postId,
    required String postTitle,
    required String postType,
  }) => _repository.suggestFulfillment(
    requestId: requestId,
    postId: postId,
    postTitle: postTitle,
    postType: postType,
  );
}
