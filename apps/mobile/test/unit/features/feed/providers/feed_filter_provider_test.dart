import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/feed/presentation/providers/feed_filter_provider.dart';

ProviderContainer _container() => ProviderContainer();

void main() {
  group('FeedFilterState.activeCount', () {
    test('is 0 when no filters set', () {
      expect(const FeedFilterState().activeCount, 0);
    });

    test('counts year, courseId, moduleNumber independently', () {
      const state = FeedFilterState(year: 2, courseId: 'CSC101', moduleNumber: 'M3');
      expect(state.activeCount, 3);
    });

    test('sortOrder does not contribute to activeCount', () {
      const state = FeedFilterState(sortOrder: FeedSortOrder.recent);
      expect(state.activeCount, 0);
    });

    test('courseName does not contribute to activeCount', () {
      const state = FeedFilterState(courseId: 'CSC101', courseName: 'Calculus I');
      expect(state.activeCount, 1);
    });
  });

  group('FeedFilterNotifier', () {
    test('builds with empty FeedFilterState', () {
      final c = _container();
      addTearDown(c.dispose);
      expect(c.read(feedFilterProvider), const FeedFilterState());
    });

    test('setCourse sets courseId and courseName', () {
      final c = _container();
      addTearDown(c.dispose);
      c.read(feedFilterProvider.notifier).setCourse('CSC101', 'Calculus');
      final state = c.read(feedFilterProvider);
      expect(state.courseId, 'CSC101');
      expect(state.courseName, 'Calculus');
    });

    test('setCourse with null clears course fields', () {
      final c = _container();
      addTearDown(c.dispose);
      c.read(feedFilterProvider.notifier).setCourse('CSC101', 'Calculus');
      c.read(feedFilterProvider.notifier).setCourse(null, null);
      final state = c.read(feedFilterProvider);
      expect(state.courseId, isNull);
      expect(state.courseName, isNull);
    });

    test('setYear sets year', () {
      final c = _container();
      addTearDown(c.dispose);
      c.read(feedFilterProvider.notifier).setYear(3);
      expect(c.read(feedFilterProvider).year, 3);
    });

    test('setModule sets moduleNumber', () {
      final c = _container();
      addTearDown(c.dispose);
      c.read(feedFilterProvider.notifier).setModule('M2');
      expect(c.read(feedFilterProvider).moduleNumber, 'M2');
    });

    test('clear resets to default FeedFilterState', () {
      final c = _container();
      addTearDown(c.dispose);
      c.read(feedFilterProvider.notifier).setCourse('CSC101', 'Calculus');
      c.read(feedFilterProvider.notifier).setYear(2);
      c.read(feedFilterProvider.notifier).clear();
      expect(c.read(feedFilterProvider), const FeedFilterState());
    });
  });
}
