import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_filter_provider.g.dart';

enum FeedSortOrder { recent }

class FeedFilterState {
  const FeedFilterState({
    this.sortOrder = FeedSortOrder.recent,
    this.year,
    this.courseId,
    this.courseName,
    this.moduleNumber,
  });

  final FeedSortOrder sortOrder;
  final int? year;
  final String? courseId;
  final String? courseName;
  final String? moduleNumber;

  int get activeCount =>
      (year != null ? 1 : 0) +
      (courseId != null ? 1 : 0) +
      (moduleNumber != null ? 1 : 0);

  static const _absent = Object();

  FeedFilterState copyWith({
    FeedSortOrder? sortOrder,
    Object? year = _absent,
    Object? courseId = _absent,
    Object? courseName = _absent,
    Object? moduleNumber = _absent,
  }) => FeedFilterState(
    sortOrder: sortOrder ?? this.sortOrder,
    year: identical(year, _absent) ? this.year : year as int?,
    courseId: identical(courseId, _absent)
        ? this.courseId
        : courseId as String?,
    courseName: identical(courseName, _absent)
        ? this.courseName
        : courseName as String?,
    moduleNumber: identical(moduleNumber, _absent)
        ? this.moduleNumber
        : moduleNumber as String?,
  );

  @override
  bool operator ==(Object other) =>
      other is FeedFilterState &&
      other.sortOrder == sortOrder &&
      other.year == year &&
      other.courseId == courseId &&
      other.courseName == courseName &&
      other.moduleNumber == moduleNumber;

  @override
  int get hashCode =>
      Object.hash(sortOrder, year, courseId, courseName, moduleNumber);
}

@riverpod
class FeedFilter extends _$FeedFilter {
  @override
  FeedFilterState build() => const FeedFilterState();

  void setCourse(String? courseId, String? courseName) {
    state = state.copyWith(
      courseId: courseId,
      courseName: courseId == null ? null : courseName,
      moduleNumber: null,
    );
  }

  void setYear(int? year) {
    state = state.copyWith(year: year);
  }

  void setModule(String? moduleNumber) {
    state = state.copyWith(moduleNumber: moduleNumber);
  }

  void setSortOrder(FeedSortOrder order) {
    state = state.copyWith(sortOrder: order);
  }

  void clear() => state = const FeedFilterState();
}
