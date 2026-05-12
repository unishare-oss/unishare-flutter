// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/requests/domain/repositories/request_repository.dart';

class RemoveSuggestion {
  const RemoveSuggestion(this._repository);
  final RequestRepository _repository;

  Future<void> call({
    required String requestId,
    required String suggestionId,
  }) => _repository.removeSuggestion(
    requestId: requestId,
    suggestionId: suggestionId,
  );
}
