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
    state = FeedFilterState(
      sortOrder: state.sortOrder,
      year: state.year,
      courseId: courseId,
      courseName: courseName,
      moduleNumber: state.moduleNumber,
    );
  }

  void setYear(int? year) {
    state = FeedFilterState(
      sortOrder: state.sortOrder,
      year: year,
      courseId: state.courseId,
      courseName: state.courseName,
      moduleNumber: state.moduleNumber,
    );
  }

  void setModule(String? moduleNumber) {
    state = FeedFilterState(
      sortOrder: state.sortOrder,
      year: state.year,
      courseId: state.courseId,
      courseName: state.courseName,
      moduleNumber: moduleNumber,
    );
  }

  void setSortOrder(FeedSortOrder order) {
    state = FeedFilterState(
      sortOrder: order,
      year: state.year,
      courseId: state.courseId,
      courseName: state.courseName,
      moduleNumber: state.moduleNumber,
    );
  }

  void clear() => state = const FeedFilterState();
}
