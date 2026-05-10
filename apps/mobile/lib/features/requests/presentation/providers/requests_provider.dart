import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/requests/domain/entities/content_request.dart';
import 'package:unishare_mobile/features/requests/presentation/providers/request_repository_provider.dart';

part 'requests_provider.g.dart';

/// Filter params for the requests stream.
class RequestsFilter {
  const RequestsFilter({
    this.departmentId,
    this.year,
    this.courseId,
    this.status,
  });

  final String? departmentId;
  final String? year;
  final String? courseId;
  final RequestStatus? status;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RequestsFilter &&
        other.departmentId == departmentId &&
        other.year == year &&
        other.courseId == courseId &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(departmentId, year, courseId, status);
}

@riverpod
Stream<List<ContentRequest>> requests(Ref ref, RequestsFilter filter) {
  final useCase = ref.watch(watchRequestsUseCaseProvider);
  return useCase(
    departmentId: filter.departmentId,
    year: filter.year,
    courseId: filter.courseId,
    status: filter.status,
  );
}
