import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:unishare_mobile/features/post/data/datasources/ai_reindex_datasource.dart';
import 'package:unishare_mobile/features/post/data/datasources/ai_summarize_datasource.dart';
import 'package:unishare_mobile/features/post/data/datasources/feed_cache.dart';
import 'package:unishare_mobile/features/post/data/datasources/post_firestore_datasource.dart';
import 'package:unishare_mobile/features/post/data/datasources/post_storage_datasource.dart';
import 'package:unishare_mobile/features/post/data/models/post_draft_model.dart';
import 'package:unishare_mobile/features/post/data/repositories/post_repository_impl.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeAiSummarizeDatasource extends AiSummarizeDatasource {
  Map<String, dynamic>? result;
  Object? error;
  String? capturedFileUrl;
  List<String>? capturedExistingTags;

  _FakeAiSummarizeDatasource({this.result, this.error});

  @override
  Future<Map<String, dynamic>> call({
    required String fileUrl,
    required String filename,
    List<String> existingTags = const [],
    String? postId,
    String? title,
  }) async {
    capturedFileUrl = fileUrl;
    capturedExistingTags = existingTags;
    if (error != null) throw error!;
    return result ?? {'summaryStatus': 'done', 'summary': 'Test summary'};
  }
}

class _FakeDatasource extends PostFirestoreDatasource {
  final StreamController<List<Post>> _ctrl =
      StreamController<List<Post>>.broadcast();

  String? lastSummaryStatus;
  String? lastSummary;
  String? lastExtractedText;
  bool? lastExtractedTextTruncated;
  List<String>? lastAiTags;

  void emit(List<Post> posts) => _ctrl.add(posts);
  void close() => _ctrl.close();

  @override
  Stream<List<Post>> watchFeed({int limit = 20}) => _ctrl.stream;

  @override
  Future<void> updatePostSummary(
    String postId,
    String? summary,
    String summaryStatus, {
    String? extractedText,
    bool? extractedTextTruncated,
    List<String>? aiTags,
  }) async {
    lastSummary = summary;
    lastSummaryStatus = summaryStatus;
    lastExtractedText = extractedText;
    lastExtractedTextTruncated = extractedTextTruncated;
    lastAiTags = aiTags;
  }

  @override
  Future<void> updatePost({
    required String postId,
    required String title,
    required String description,
    required List<String> tags,
    String? externalUrl,
    required String moduleNumber,
    required bool descriptionChanged,
    required SummaryStatus? currentSummaryStatus,
  }) async {}
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
    _FakeAiSummarizeDatasource? aiDatasource,
    _MockReindexDatasource? aiReindexDatasource,
  }) => PostRepositoryImpl(
    firestoreDatasource: datasource,
    storageDatasource: PostStorageDatasource(),
    draftBox: draftBox,
    feedCache: feedCache,
    cacheTtl: cacheTtl,
    aiSummarizeDatasource: aiDatasource,
    aiReindexDatasource: aiReindexDatasource,
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

  group('triggerSummarize', () {
    test(
      'success path — updatePostSummary called with worker response',
      () async {
        final ai = _FakeAiSummarizeDatasource(
          result: {
            'summaryStatus': 'done',
            'summary': 'Great summary',
            'extractedText': 'The full source text…',
            'extractedTextTruncated': false,
            'aiTags': ['krebs-cycle', 'atp-synthesis', 'mitochondria'],
          },
        );
        final ds = _FakeDatasource();
        final repo = makeRepo(
          feedCache: FeedCache(),
          datasource: ds,
          aiDatasource: ai,
        );

        repo.triggerSummarize(
          'post-1',
          'https://cdn.example.com/posts/file.pdf',
          'file.pdf',
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(ds.lastSummaryStatus, 'done');
        expect(ds.lastSummary, 'Great summary');
        expect(ds.lastExtractedText, 'The full source text…');
        expect(ds.lastExtractedTextTruncated, false);
        expect(
          ds.lastAiTags,
          equals(['krebs-cycle', 'atp-synthesis', 'mitochondria']),
        );
      },
    );

    test(
      'image response — extractedText from transcription persisted with truncated flag',
      () async {
        final ai = _FakeAiSummarizeDatasource(
          result: {
            'summaryStatus': 'done',
            'summary': 'Handwritten notes on Krebs cycle',
            'extractedText': 'Step 1: Acetyl-CoA + Oxaloacetate → Citrate…',
            'extractedTextTruncated': true,
          },
        );
        final ds = _FakeDatasource();
        final repo = makeRepo(
          feedCache: FeedCache(),
          datasource: ds,
          aiDatasource: ai,
        );

        repo.triggerSummarize(
          'post-image',
          'https://cdn.example.com/posts/notes.jpg',
          'notes.jpg',
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(ds.lastSummaryStatus, 'done');
        expect(ds.lastExtractedText, startsWith('Step 1: Acetyl-CoA'));
        expect(ds.lastExtractedTextTruncated, true);
      },
    );

    test(
      'error path — updatePostSummary called with null and error status',
      () async {
        final ai = _FakeAiSummarizeDatasource(
          error: Exception('network failure'),
        );
        final ds = _FakeDatasource();
        final repo = makeRepo(
          feedCache: FeedCache(),
          datasource: ds,
          aiDatasource: ai,
        );

        repo.triggerSummarize(
          'post-1',
          'https://cdn.example.com/posts/file.pdf',
          'file.pdf',
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(ds.lastSummaryStatus, 'error');
        expect(ds.lastSummary, isNull);
      },
    );

    test(
      'flagged response — updatePostSummary called with flagged status',
      () async {
        final ai = _FakeAiSummarizeDatasource(
          result: {'summaryStatus': 'flagged', 'summary': null},
        );
        final ds = _FakeDatasource();
        final repo = makeRepo(
          feedCache: FeedCache(),
          datasource: ds,
          aiDatasource: ai,
        );

        repo.triggerSummarize(
          'post-1',
          'https://cdn.example.com/posts/file.pdf',
          'file.pdf',
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(ds.lastSummaryStatus, 'flagged');
        expect(ds.lastSummary, isNull);
      },
    );
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

  group('updatePost reindex trigger', () {
    test('calls reindex datasource once when titleChanged', () async {
      final mockReindex = _MockReindexDatasource();
      final datasource = _FakeDatasource();
      final repo = makeRepo(
        feedCache: FeedCache(),
        datasource: datasource,
        aiReindexDatasource: mockReindex,
      );

      await repo.updatePost(
        postId: 'p1',
        title: 'New title',
        description: 'unchanged description',
        tags: const [],
        moduleNumber: '1',
        descriptionChanged: false,
        titleChanged: true,
        currentSummaryStatus: null,
      );

      await Future<void>.delayed(Duration.zero);
      expect(mockReindex.calls, hasLength(1));
      expect(mockReindex.calls.single.postId, 'p1');
      expect(mockReindex.calls.single.title, 'New title');
    });

    test('calls reindex datasource once when descriptionChanged', () async {
      final mockReindex = _MockReindexDatasource();
      final datasource = _FakeDatasource();
      final repo = makeRepo(
        feedCache: FeedCache(),
        datasource: datasource,
        aiReindexDatasource: mockReindex,
      );

      await repo.updatePost(
        postId: 'p1',
        title: 'unchanged title',
        description: 'New description',
        tags: const [],
        moduleNumber: '1',
        descriptionChanged: true,
        titleChanged: false,
        currentSummaryStatus: null,
      );

      await Future<void>.delayed(Duration.zero);
      expect(mockReindex.calls, hasLength(1));
    });

    test('does not call reindex when neither changed', () async {
      final mockReindex = _MockReindexDatasource();
      final datasource = _FakeDatasource();
      final repo = makeRepo(
        feedCache: FeedCache(),
        datasource: datasource,
        aiReindexDatasource: mockReindex,
      );

      await repo.updatePost(
        postId: 'p1',
        title: 'same',
        description: 'same',
        tags: const [],
        moduleNumber: '1',
        descriptionChanged: false,
        titleChanged: false,
        currentSummaryStatus: null,
      );

      await Future<void>.delayed(Duration.zero);
      expect(mockReindex.calls, isEmpty);
    });

    test('swallows reindex failure without rethrowing', () async {
      final failingReindex = _MockReindexDatasource(shouldFail: true);
      final datasource = _FakeDatasource();
      final repo = makeRepo(
        feedCache: FeedCache(),
        datasource: datasource,
        aiReindexDatasource: failingReindex,
      );

      await expectLater(
        repo.updatePost(
          postId: 'p1',
          title: 'New',
          description: 'd',
          tags: const [],
          moduleNumber: '1',
          descriptionChanged: false,
          titleChanged: true,
          currentSummaryStatus: null,
        ),
        completes,
      );
    });
  });
}

class _MockReindexDatasource implements AiReindexDatasource {
  _MockReindexDatasource({this.shouldFail = false});

  final bool shouldFail;
  final List<({String postId, String title, String description})> calls = [];

  @override
  Future<bool> call({
    required String postId,
    required String title,
    required String description,
  }) async {
    calls.add((postId: postId, title: title, description: description));
    if (shouldFail) throw Exception('reindex failed');
    return true;
  }
}
