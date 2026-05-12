import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/requests/domain/entities/content_request.dart';
import 'package:unishare_mobile/features/requests/presentation/providers/request_repository_provider.dart';

part 'requests_provider.g.dart';

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

  RequestsFilter copyWith({
    String? departmentId,
    String? year,
    String? courseId,
    RequestStatus? status,
    bool clearDepartmentId = false,
    bool clearYear = false,
    bool clearCourseId = false,
    bool clearStatus = false,
  }) {
    return RequestsFilter(
      departmentId: clearDepartmentId
          ? null
          : (departmentId ?? this.departmentId),
      year: clearYear ? null : (year ?? this.year),
      courseId: clearCourseId ? null : (courseId ?? this.courseId),
      status: clearStatus ? null : (status ?? this.status),
    );
  }

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
class RequestsFilterState extends _$RequestsFilterState {
  @override
  RequestsFilter build() => const RequestsFilter();

  void setStatus(RequestStatus? status) {
    state = state.copyWith(status: status, clearStatus: status == null);
  }

  void setDepartmentId(String? id) {
    state = state.copyWith(
      departmentId: id,
      clearDepartmentId: id == null,
      clearYear: true,
      clearCourseId: true,
    );
  }

  void setYear(String? year) {
    state = state.copyWith(
      year: year,
      clearYear: year == null,
      clearCourseId: true,
    );
  }

  void setCourseId(String? id) {
    state = state.copyWith(courseId: id, clearCourseId: id == null);
  }
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
