import 'package:unishare_mobile/features/requests/domain/entities/content_request.dart';
import 'package:unishare_mobile/features/requests/domain/repositories/request_repository.dart';

class WatchRequest {
  const WatchRequest(this._repo);
  final RequestRepository _repo;

  Stream<ContentRequest> call(String requestId) =>
      _repo.watchRequest(requestId);
}
