import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:unishare_mobile/features/post/data/datasources/feed_cache.dart';
import 'package:unishare_mobile/features/post/data/datasources/post_firestore_datasource.dart';
import 'package:unishare_mobile/features/post/data/datasources/post_storage_datasource.dart';
import 'package:unishare_mobile/features/post/data/models/post_draft_model.dart';
import 'package:unishare_mobile/features/post/data/repositories/post_repository_impl.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';

// ---------------------------------------------------------------------------
// Fake datasource — overrides watchFeed; _firestore is never accessed
// ---------------------------------------------------------------------------

class _FakeDatasource extends PostFirestoreDatasource {
  final StreamController<List<Post>> _ctrl =
      StreamController<List<Post>>.broadcast();

  void emit(List<Post> posts) => _ctrl.add(posts);

  void close() => _ctrl.close();

  @override
  Stream<List<Post>> watchFeed({int limit = 20}) => _ctrl.stream;
}

// ---------------------------------------------------------------------------
// Helper: minimal Post
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late Directory tempDir;
  late Box<PostDraftModel> draftBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    Hive.registerAdapter(PostDraftModelAdapter());
    draftBox = await Hive.openBox<PostDraftModel>('test_drafts');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  tearDown(() async => draftBox.clear());

  PostRepositoryImpl makeRepo({
    required FeedCache feedCache,
    required _FakeDatasource datasource,
    Duration cacheTtl = const Duration(minutes: 5),
  }) => PostRepositoryImpl(
    firestoreDatasource: datasource,
    storageDatasource: PostStorageDatasource(),
    draftBox: draftBox,
    feedCache: feedCache,
    cacheTtl: cacheTtl,
  );

  group('watchFeed — cache miss', () {
    test('emits nothing until datasource emits when cache is empty', () async {
      final datasource = _FakeDatasource();
      final repo = makeRepo(feedCache: FeedCache(), datasource: datasource);

      final emissions = <List<Post>>[];
      final sub = repo.watchFeed().listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions, isEmpty);

      datasource.emit([_post('p1')]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions.length, 1);
      expect(emissions.first.single.id, 'p1');

      // Close inner stream before cancelling — prevents await sub.cancel() from hanging
      // when the async* generator is blocked inside await-for on the broadcast stream.
      datasource.close();
      await sub.cancel();
    });

    test('updates cache after Firestore emission', () async {
      final datasource = _FakeDatasource();
      final cache = FeedCache();
      final repo = makeRepo(feedCache: cache, datasource: datasource);

      final sub = repo.watchFeed().listen((_) {});
      // Wait for the async* generator to reach its await-for and subscribe.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      datasource.emit([_post('p1')]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cache.isValid(const Duration(minutes: 5)), isTrue);
      expect(cache.posts.single.id, 'p1');

      datasource.close();
      await sub.cancel();
    });
  });

  group('watchFeed — cache hit', () {
    test('emits cached list immediately before Firestore responds', () async {
      final datasource = _FakeDatasource();
      final cache = FeedCache()..update([_post('cached')]);
      final repo = makeRepo(feedCache: cache, datasource: datasource);

      final emissions = <List<Post>>[];
      final sub = repo.watchFeed().listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions.length, 1);
      expect(emissions.first.single.id, 'cached');

      datasource.emit([_post('fresh')]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions.length, 2);
      expect(emissions[1].single.id, 'fresh');

      datasource.close();
      await sub.cancel();
    });

    test('does not yield cache when TTL is expired', () async {
      final datasource = _FakeDatasource();
      final cache = FeedCache()..update([_post('stale')]);
      final repo = makeRepo(
        feedCache: cache,
        datasource: datasource,
        cacheTtl: Duration.zero,
      );

      final emissions = <List<Post>>[];
      final sub = repo.watchFeed().listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions, isEmpty);

      datasource.close();
      await sub.cancel();
    });
  });

  group('cache invalidation', () {
    test('invalidate clears cache so next watchFeed skips the seed', () async {
      final cache = FeedCache()..update([_post('old')]);
      cache.invalidate();

      final datasource = _FakeDatasource();
      final repo = makeRepo(feedCache: cache, datasource: datasource);

      final emissions = <List<Post>>[];
      final sub = repo.watchFeed().listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions, isEmpty);

      datasource.close();
      await sub.cancel();
    });
  });
}
