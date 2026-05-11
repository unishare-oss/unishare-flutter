// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/requests/domain/repositories/request_repository.dart';

class DeleteRequest {
  const DeleteRequest(this._repository);
  final RequestRepository _repository;

  Future<void> call(String requestId) => _repository.deleteRequest(requestId);
}
