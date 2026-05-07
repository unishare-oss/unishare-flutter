# Feed Caching Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a 5-minute in-memory cache to the feed stream so re-navigation shows posts instantly (seed-before-Firestore pattern), with invalidation when a new post is published.

**Architecture:** A pure-Dart `FeedCache` class is injected into `PostRepositoryImpl`. `watchFeed()` becomes an `async*` generator that yields the cached list first (if within TTL), then continues emitting from the Firestore stream — updating the cache on every emission. `publishDraft` calls `feedCache.invalidate()` on success. TTL is a constructor parameter (default 5 min) so tests can control expiry without sleeping.

**Tech Stack:** Dart `async*` generators, Hive (existing, for draftBox in test setup), flutter_test.

---

## File Map

| Action | File |
|--------|------|
| Create | `apps/mobile/lib/features/post/data/datasources/feed_cache.dart` |
| Modify (1 line) | `apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart` |
| Modify | `apps/mobile/lib/features/post/data/repositories/post_repository_impl.dart` |
| Modify | `apps/mobile/lib/features/post/presentation/providers/post_repository_provider.dart` |
| Create | `apps/mobile/test/unit/features/post/data/datasources/feed_cache_test.dart` |
| Create | `apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart` |

---

## Task 1: `FeedCache` class with unit tests

**Files:**
- Create: `apps/mobile/lib/features/post/data/datasources/feed_cache.dart`
- Create: `apps/mobile/test/unit/features/post/data/datasources/feed_cache_test.dart`

- [ ] **Step 1.1: Write the failing tests**

Create `apps/mobile/test/unit/features/post/data/datasources/feed_cache_test.dart`:

```dart
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
```

- [ ] **Step 1.2: Run to confirm failure**

```bash
cd apps/mobile && flutter test test/unit/features/post/data/datasources/feed_cache_test.dart
```

Expected: compile error — `FeedCache` doesn't exist yet.

- [ ] **Step 1.3: Create `FeedCache`**

Create `apps/mobile/lib/features/post/data/datasources/feed_cache.dart`:

```dart
import 'package:unishare_mobile/features/post/domain/entities/post.dart';

class FeedCache {
  List<Post>? _posts;
  DateTime? _cachedAt;

  bool isValid(Duration ttl) =>
      _posts != null &&
      _cachedAt != null &&
      DateTime.now().difference(_cachedAt!) < ttl;

  List<Post> get posts {
    if (_posts == null) throw StateError('feed_cache_empty');
    return List.unmodifiable(_posts!);
  }

  void update(List<Post> posts) {
    _posts = posts;
    _cachedAt = DateTime.now();
  }

  void invalidate() {
    _posts = null;
    _cachedAt = null;
  }
}
```

- [ ] **Step 1.4: Run tests to confirm they pass**

```bash
cd apps/mobile && flutter test test/unit/features/post/data/datasources/feed_cache_test.dart
```

Expected: all 8 tests pass.

- [ ] **Step 1.5: Commit**

```bash
git add apps/mobile/lib/features/post/data/datasources/feed_cache.dart \
        apps/mobile/test/unit/features/post/data/datasources/feed_cache_test.dart
git commit -m "feat(cache): add FeedCache with TTL, invalidate, and unmodifiable view"
```

---

## Task 2: Make `PostFirestoreDatasource._firestore` lazy

This single-line change lets tests subclass `PostFirestoreDatasource` and override `watchFeed` without triggering `FirebaseFirestore.instance` at construction time.

**Files:**
- Modify: `apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart`

- [ ] **Step 2.1: Add `late` to the `_firestore` field**

In `post_firestore_datasource.dart`, change line 9 from:

```dart
  final _firestore = FirebaseFirestore.instance;
```

to:

```dart
  late final _firestore = FirebaseFirestore.instance;
```

- [ ] **Step 2.2: Verify existing tests still pass**

```bash
cd apps/mobile && flutter test test/unit/features/post/
```

Expected: all existing tests pass (this change is behaviour-neutral).

- [ ] **Step 2.3: Commit**

```bash
git add apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart
git commit -m "refactor(datasource): make _firestore lazy to enable test subclassing"
```

---

## Task 3: Update `PostRepositoryImpl` to inject and use `FeedCache`

**Files:**
- Modify: `apps/mobile/lib/features/post/data/repositories/post_repository_impl.dart`

- [ ] **Step 3.1: Update the constructor and `watchFeed`**

Replace the entire `post_repository_impl.dart` with the updated version below. Key changes:
1. Add `feedCache` and `cacheTtl` constructor parameters
2. `watchFeed` becomes an `async*` generator that seeds from cache then relays the Firestore stream
3. `publishDraft` calls `feedCache.invalidate()` after the successful `createPost` call

```dart
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:unishare_mobile/features/post/data/datasources/feed_cache.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';
import 'package:unishare_mobile/features/post/data/datasources/post_firestore_datasource.dart';
import 'package:unishare_mobile/features/post/data/datasources/post_storage_datasource.dart';
import 'package:unishare_mobile/features/post/data/models/post_draft_model.dart';

class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl({
    required this.firestoreDatasource,
    required this.storageDatasource,
    required this.draftBox,
    required this.feedCache,
    this.cacheTtl = const Duration(minutes: 5),
  });

  final PostFirestoreDatasource firestoreDatasource;
  final PostStorageDatasource storageDatasource;
  final Box<PostDraftModel> draftBox;
  final FeedCache feedCache;
  final Duration cacheTtl;

  @override
  Stream<List<Post>> watchFeed({int limit = 20}) async* {
    if (feedCache.isValid(cacheTtl)) {
      yield feedCache.posts;
    }
    await for (final posts in firestoreDatasource.watchFeed(limit: limit)) {
      feedCache.update(posts);
      yield posts;
    }
  }

  @override
  Stream<Post> watchPost(String postId) =>
      firestoreDatasource.watchPost(postId);

  @override
  Future<void> saveDraft(PostDraft draft) async {
    await draftBox.put(draft.id, PostDraftModel.fromEntity(draft));
  }

  @override
  Future<void> removeDraft(String draftId) async {
    await draftBox.delete(draftId);
  }

  @override
  Future<List<PostDraft>> loadDraftQueue() async {
    return draftBox.values.map((m) => m.toEntity()).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<void> publishDraft(
    PostDraft draft, {
    void Function(double progress)? onProgress,
    Map<String, Uint8List>? fileDataOverride,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('not_authenticated');

    var current = draft;
    final paths = draft.localMediaPaths;

    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      if (current.uploadedUrls.containsKey(path)) continue;

      try {
        final progressFn = onProgress != null
            ? (fp) => onProgress((i + fp) / paths.length)
            : null;
        final overrideBytes = fileDataOverride?[path];
        final url = overrideBytes != null
            ? await storageDatasource.uploadBytes(
                overrideBytes,
                path,
                user.uid,
                onProgress: progressFn,
              )
            : await storageDatasource.upload(
                path,
                user.uid,
                onProgress: progressFn,
              );

        final newUrls = Map<String, String>.from(current.uploadedUrls)
          ..[path] = url;
        current = current.copyWith(uploadedUrls: newUrls);
        await saveDraft(current);
      } catch (e) {
        await saveDraft(
          current.copyWith(
            status: DraftStatus.error,
            errorMessage: e.toString(),
          ),
        );
        rethrow;
      }
    }

    String? codeSnippetUrl;
    if (draft.codeSnippet != null) {
      final snippet = draft.codeSnippet!;
      final ext = snippet.language.toLowerCase();
      final filename = '${snippet.filename}.$ext';
      codeSnippetUrl = await storageDatasource.uploadText(
        snippet.content,
        user.uid,
        filename,
      );
    }

    final mediaUrls = paths
        .where((p) => current.uploadedUrls.containsKey(p))
        .map((p) => current.uploadedUrls[p]!)
        .toList();

    final mediaTypes = paths
        .where((p) => current.uploadedUrls.containsKey(p))
        .map(_mediaTypeFromPath)
        .toList();

    try {
      await firestoreDatasource.createPost(
        draft: current,
        mediaUrls: mediaUrls,
        mediaTypes: mediaTypes,
        authorName: draft.postingIdentity == PostingIdentity.anonymous
            ? ''
            : (user.displayName ?? ''),
        authorAvatar: draft.postingIdentity == PostingIdentity.anonymous
            ? ''
            : (user.photoURL ?? ''),
        codeSnippetUrl: codeSnippetUrl,
      );
      feedCache.invalidate();
      await removeDraft(draft.id);
    } catch (e) {
      await saveDraft(
        current.copyWith(
          uploadedUrls: current.uploadedUrls,
          status: DraftStatus.queued,
        ),
      );
      rethrow;
    }
  }

  static String _mediaTypeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return 'image';
      case 'pdf':
        return 'pdf';
      case 'mp4':
      case 'mov':
      case 'avi':
        return 'video';
      default:
        return 'image';
    }
  }
}
```

- [ ] **Step 3.2: Verify the file compiles**

```bash
cd apps/mobile && flutter analyze lib/features/post/data/repositories/post_repository_impl.dart
```

Expected: no errors (provider will error until Task 5 — that's fine).

- [ ] **Step 3.3: Commit**

```bash
git add apps/mobile/lib/features/post/data/repositories/post_repository_impl.dart
git commit -m "feat(cache): inject FeedCache into PostRepositoryImpl, seed watchFeed stream, invalidate on publish"
```

---

## Task 4: Unit tests for `PostRepositoryImpl` cache behavior

Tests for cache hit (emits cached data first) and cache miss (goes straight to Firestore). Uses a `_FakeDatasource` subclass — safe because `PostFirestoreDatasource._firestore` is now `late final` (Task 2).

**Files:**
- Create: `apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart`

- [ ] **Step 4.1: Write the tests**

Create `apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart`:

```dart
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

// ---------------------------------------------------------------------------
// Fake datasource — overrides watchFeed; _firestore is never accessed
// ---------------------------------------------------------------------------

class _FakeDatasource extends PostFirestoreDatasource {
  final StreamController<List<Post>> _ctrl =
      StreamController<List<Post>>.broadcast();

  void emit(List<Post> posts) => _ctrl.add(posts);

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

  PostRepositoryImpl _makeRepo({
    required FeedCache feedCache,
    required _FakeDatasource datasource,
    Duration cacheTtl = const Duration(minutes: 5),
  }) =>
      PostRepositoryImpl(
        firestoreDatasource: datasource,
        storageDatasource: PostStorageDatasource(),
        draftBox: draftBox,
        feedCache: feedCache,
        cacheTtl: cacheTtl,
      );

  group('watchFeed — cache miss', () {
    test('emits nothing until datasource emits when cache is empty', () async {
      final datasource = _FakeDatasource();
      final repo = _makeRepo(feedCache: FeedCache(), datasource: datasource);

      final emissions = <List<Post>>[];
      final sub = repo.watchFeed().listen(emissions.add);

      // No cache → no immediate emission
      await Future<void>.delayed(Duration.zero);
      expect(emissions, isEmpty);

      // Firestore emits → repo emits
      datasource.emit([_post('p1')]);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.length, 1);
      expect(emissions.first.single.id, 'p1');

      await sub.cancel();
    });

    test('updates cache after Firestore emission', () async {
      final datasource = _FakeDatasource();
      final cache = FeedCache();
      final repo = _makeRepo(feedCache: cache, datasource: datasource);

      final sub = repo.watchFeed().listen((_) {});
      datasource.emit([_post('p1')]);
      await Future<void>.delayed(Duration.zero);

      expect(cache.isValid(const Duration(minutes: 5)), isTrue);
      expect(cache.posts.single.id, 'p1');

      await sub.cancel();
    });
  });

  group('watchFeed — cache hit', () {
    test('emits cached list immediately before Firestore responds', () async {
      final datasource = _FakeDatasource();
      final cache = FeedCache()..update([_post('cached')]);
      final repo = _makeRepo(feedCache: cache, datasource: datasource);

      final emissions = <List<Post>>[];
      final sub = repo.watchFeed().listen(emissions.add);

      // Immediately yields cached data
      await Future<void>.delayed(Duration.zero);
      expect(emissions.length, 1);
      expect(emissions.first.single.id, 'cached');

      // Then Firestore emits a fresh batch
      datasource.emit([_post('fresh')]);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.length, 2);
      expect(emissions[1].single.id, 'fresh');

      await sub.cancel();
    });

    test('does not yield cache when TTL is expired', () async {
      final datasource = _FakeDatasource();
      final cache = FeedCache()..update([_post('stale')]);
      // Pass Duration.zero so cache is immediately expired
      final repo = _makeRepo(
        feedCache: cache,
        datasource: datasource,
        cacheTtl: Duration.zero,
      );

      final emissions = <List<Post>>[];
      final sub = repo.watchFeed().listen(emissions.add);

      await Future<void>.delayed(Duration.zero);
      expect(emissions, isEmpty);

      await sub.cancel();
    });
  });

  group('cache invalidation', () {
    test('invalidate clears the cache so next watchFeed skips the seed', () async {
      final cache = FeedCache()..update([_post('old')]);
      cache.invalidate();

      final datasource = _FakeDatasource();
      final repo = _makeRepo(feedCache: cache, datasource: datasource);

      final emissions = <List<Post>>[];
      final sub = repo.watchFeed().listen(emissions.add);

      await Future<void>.delayed(Duration.zero);
      expect(emissions, isEmpty, reason: 'invalidated cache must not seed the stream');

      await sub.cancel();
    });
  });
}
```

- [ ] **Step 4.2: Run to confirm failure**

```bash
cd apps/mobile && flutter test test/unit/features/post/data/repositories/post_repository_impl_test.dart
```

Expected: compile error — Task 3 must be complete first. If Task 3 is done, tests may fail due to constructor mismatch (the provider still passes the old signature — that's fine, only the test file matters here).

- [ ] **Step 4.3: Run tests to confirm they pass**

```bash
cd apps/mobile && flutter test test/unit/features/post/data/repositories/post_repository_impl_test.dart
```

Expected: all 6 tests pass.

- [ ] **Step 4.4: Commit**

```bash
git add apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart
git commit -m "test(cache): add watchFeed cache hit, miss, and invalidation tests"
```

---

## Task 5: Wire up `FeedCache` in the provider

**Files:**
- Modify: `apps/mobile/lib/features/post/presentation/providers/post_repository_provider.dart`

- [ ] **Step 5.1: Add `feedCacheProvider` and inject it into `postRepository`**

Update `post_repository_provider.dart`. Add the import and provider, then pass `feedCache` to `PostRepositoryImpl`:

At the top, add the import:
```dart
import 'package:unishare_mobile/features/post/data/datasources/feed_cache.dart';
```

After the `postStorageDatasource` provider, add:
```dart
@Riverpod(keepAlive: true)
FeedCache feedCache(Ref ref) => FeedCache();
```

Change the `postRepository` provider body from:
```dart
@Riverpod(keepAlive: true)
PostRepository postRepository(Ref ref) {
  return PostRepositoryImpl(
    firestoreDatasource: ref.watch(postFirestoreDatasourceProvider),
    storageDatasource: ref.watch(postStorageDatasourceProvider),
    draftBox: Hive.box<PostDraftModel>('draft_queue'),
  );
}
```

to:
```dart
@Riverpod(keepAlive: true)
PostRepository postRepository(Ref ref) {
  return PostRepositoryImpl(
    firestoreDatasource: ref.watch(postFirestoreDatasourceProvider),
    storageDatasource: ref.watch(postStorageDatasourceProvider),
    draftBox: Hive.box<PostDraftModel>('draft_queue'),
    feedCache: ref.watch(feedCacheProvider),
  );
}
```

- [ ] **Step 5.2: Regenerate Riverpod code**

```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
```

Expected: `post_repository_provider.g.dart` regenerated with `feedCacheProvider`.

- [ ] **Step 5.3: Run all post tests**

```bash
cd apps/mobile && flutter test test/unit/features/post/ && flutter test test/widget/features/post/
```

Expected: all tests pass.

- [ ] **Step 5.4: Run `flutter analyze`**

```bash
cd apps/mobile && flutter analyze
```

Expected: no issues.

- [ ] **Step 5.5: Commit**

```bash
git add apps/mobile/lib/features/post/presentation/providers/post_repository_provider.dart \
        apps/mobile/lib/features/post/presentation/providers/post_repository_provider.g.dart
git commit -m "feat(cache): wire FeedCache into postRepository provider"
```

---

## Task 6: Full test run and final check

- [ ] **Step 6.1: Run the full test suite**

```bash
cd apps/mobile && flutter test
```

Expected: all tests pass with no regressions.

- [ ] **Step 6.2: Run analyzer**

```bash
cd apps/mobile && flutter analyze && dart format --set-exit-if-changed .
```

Expected: zero issues, no formatting changes needed.

- [ ] **Step 6.3: Manual smoke test (optional but recommended)**

Run the app, navigate to the feed, navigate away, navigate back. The feed should show posts immediately (cache hit) instead of a blank/loading state. Check logcat/console for no errors.

```bash
cd apps/mobile && flutter run
```
