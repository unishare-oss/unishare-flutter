// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/requests/domain/entities/suggestion.dart';
import 'package:unishare_mobile/features/requests/domain/repositories/request_repository.dart';

class WatchSuggestions {
  const WatchSuggestions(this._repository);
  final RequestRepository _repository;

  Stream<List<Suggestion>> call(String requestId) =>
      _repository.watchSuggestions(requestId);
}
