// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/requests/domain/repositories/request_repository.dart';

class AcceptSuggestion {
  const AcceptSuggestion(this._repository);
  final RequestRepository _repository;

  Future<void> call({
    required String requestId,
    required String suggestionId,
    required String postId,
    required String postTitle,
  }) => _repository.acceptSuggestion(
    requestId: requestId,
    suggestionId: suggestionId,
    postId: postId,
    postTitle: postTitle,
  );
}
