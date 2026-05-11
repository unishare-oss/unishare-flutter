// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/requests/domain/entities/content_request.dart';
import 'package:unishare_mobile/features/requests/domain/repositories/request_repository.dart';

class WatchRequests {
  const WatchRequests(this._repository);
  final RequestRepository _repository;

  Stream<List<ContentRequest>> call({
    String? departmentId,
    String? year,
    String? courseId,
    RequestStatus? status,
  }) => _repository.watchRequests(
    departmentId: departmentId,
    year: year,
    courseId: courseId,
    status: status,
  );
}
