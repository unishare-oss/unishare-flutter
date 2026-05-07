import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/data/datasources/feed_cache.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';

Post _post(String id) => Post(
  id: id,
  authorId: 'a',
  authorName: 'A',
  authorAvatar: '',
  postType: PostType.lectureNote,
  year: 1,
  courseId: 'c',
  title: 'T',
  description: 'D',
  postingIdentity: PostingIdentity.named,
  semester: 1,
  moduleNumber: '1',
  mediaUrls: const [],
  mediaTypes: const [],
  tags: const [],
  likesCount: 0,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late FeedCache cache;

  setUp(() => cache = FeedCache());

  group('empty cache', () {
    test('isValid returns false when no data', () {
      expect(cache.isValid(const Duration(minutes: 5)), isFalse);
    });

    test('posts throws StateError when empty', () {
      expect(() => cache.posts, throwsStateError);
    });
  });

  group('after update', () {
    setUp(() => cache.update([_post('p1'), _post('p2')]));

    test('isValid returns true within TTL', () {
      expect(cache.isValid(const Duration(minutes: 5)), isTrue);
    });

    test('isValid returns false when TTL is zero', () {
      expect(cache.isValid(Duration.zero), isFalse);
    });

    test('posts returns the stored list', () {
      expect(cache.posts.map((p) => p.id), containsAll(['p1', 'p2']));
    });

    test('posts list is unmodifiable', () {
      expect(() => cache.posts.add(_post('p3')), throwsUnsupportedError);
    });
  });

  group('after invalidate', () {
    setUp(() {
      cache.update([_post('p1')]);
      cache.invalidate();
    });

    test('isValid returns false', () {
      expect(cache.isValid(const Duration(minutes: 5)), isFalse);
    });

    test('posts throws StateError', () {
      expect(() => cache.posts, throwsStateError);
    });
  });

  test('update replaces previous data', () {
    cache.update([_post('old')]);
    cache.update([_post('new')]);
    expect(cache.posts.single.id, 'new');
  });
}
