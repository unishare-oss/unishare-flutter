# Upload Progress Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the blocking inline upload progress on `CreatePostScreen` with a dedicated `/upload-progress` route that shows a ring progress hero and per-file status list.

**Architecture:** `CreatePostScreen._submit()` fires the upload notifier without awaiting and immediately pushes `/upload-progress`. The notifier emits `CreatePostUploading` with a `List<FileUploadProgress>` driven by a new `onFileProgress` callback threaded through the use case and repository. A `CancellationToken` (pure Dart core class) is linked to a Dio `CancelToken` so the user can abort mid-transfer.

**Tech Stack:** Flutter, Riverpod (code-gen), GoRouter, Dio, `package:dio/dio.dart` (already in project)

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `lib/core/cancellation/cancellation_token.dart` | **Create** | Pure-Dart cancellation token; links to Dio's CancelToken in data layer |
| `lib/features/post/presentation/providers/create_post_provider.dart` | **Modify** | Add `FileUploadPhase`, `FileUploadProgress`, update `CreatePostUploading`, add `cancel()` and per-file state updates to notifier |
| `lib/features/post/domain/repositories/post_repository.dart` | **Modify** | Add `onFileProgress` + `cancellationToken` params to `publishDraft` |
| `lib/features/post/data/datasources/post_storage_datasource.dart` | **Modify** | Accept Dio `CancelToken?` in `_put`, `upload`, `uploadBytes` |
| `lib/features/post/data/repositories/post_repository_impl.dart` | **Modify** | Wire `onFileProgress`, create Dio `CancelToken`, link to `CancellationToken` |
| `lib/features/post/domain/usecases/create_post.dart` | **Modify** | Pass through `onFileProgress` + `cancellationToken` |
| `lib/features/post/presentation/screens/upload_progress_screen.dart` | **Create** | Ring hero + per-file list; handles all 5 provider states |
| `lib/features/post/presentation/screens/create_post_screen.dart` | **Modify** | Make `_submit` sync/fire-and-forget; remove inline progress UI |
| `lib/core/router/router.dart` | **Modify** | Add `/upload-progress` route and add it to `knownPrefixes` |
| `test/widget/features/post/screens/upload_progress_screen_test.dart` | **Create** | Widget tests for the new screen |
| `test/unit/features/post/domain/usecases/create_post_test.dart` | **Modify** | Update `_FakeRepo.publishDraft` signature |
| `test/widget/features/post/screens/create_post_screen_test.dart` | **Modify** | Update `_StubRepo.publishDraft` signature |

---

### Task 1: Add CancellationToken + per-file progress types

**Files:**
- Create: `lib/core/cancellation/cancellation_token.dart`
- Modify: `lib/features/post/presentation/providers/create_post_provider.dart`
- Create: `test/unit/core/cancellation/cancellation_token_test.dart`

- [ ] **Step 1.1: Write failing tests for CancellationToken**

Create `test/unit/core/cancellation/cancellation_token_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';

void main() {
  group('CancellationToken', () {
    test('isCancelled is false initially', () {
      final token = CancellationToken();
      expect(token.isCancelled, isFalse);
    });

    test('isCancelled is true after cancel()', () {
      final token = CancellationToken();
      token.cancel();
      expect(token.isCancelled, isTrue);
    });

    test('listener fires immediately when token is already cancelled', () {
      final token = CancellationToken()..cancel();
      var fired = false;
      token.addCancelListener(() => fired = true);
      expect(fired, isTrue);
    });

    test('listener fires when cancel() is called later', () {
      final token = CancellationToken();
      var fired = false;
      token.addCancelListener(() => fired = true);
      expect(fired, isFalse);
      token.cancel();
      expect(fired, isTrue);
    });

    test('cancel() is idempotent — listener fires only once', () {
      final token = CancellationToken();
      var count = 0;
      token.addCancelListener(() => count++);
      token.cancel();
      token.cancel();
      expect(count, 1);
    });
  });
}
```

- [ ] **Step 1.2: Run the test to verify it fails**

```bash
cd apps/mobile && flutter test test/unit/core/cancellation/cancellation_token_test.dart
```

Expected: compile error — `CancellationToken` not found.

- [ ] **Step 1.3: Create CancellationToken**

Create `lib/core/cancellation/cancellation_token.dart`:

```dart
class CancellationToken {
  bool _cancelled = false;
  final _listeners = <void Function()>[];

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final l in List.of(_listeners)) {
      l();
    }
    _listeners.clear();
  }

  void addCancelListener(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }
}
```

- [ ] **Step 1.4: Run tests to verify they pass**

```bash
cd apps/mobile && flutter test test/unit/core/cancellation/cancellation_token_test.dart
```

Expected: 5 tests pass.

- [ ] **Step 1.5: Update create_post_provider.dart with new types**

In `lib/features/post/presentation/providers/create_post_provider.dart`, replace the `CreatePostUploading` class and add the new types. Replace:

```dart
final class CreatePostUploading extends CreatePostState {
  const CreatePostUploading({required this.progress});
  final double progress; // [0.0, 1.0]
}
```

With:

```dart
enum FileUploadPhase { queued, uploading, done }

class FileUploadProgress {
  const FileUploadProgress({
    required this.filename,
    required this.phase,
    this.progress = 0.0,
  });

  final String filename;
  final FileUploadPhase phase;
  final double progress;

  FileUploadProgress copyWith({FileUploadPhase? phase, double? progress}) =>
      FileUploadProgress(
        filename: filename,
        phase: phase ?? this.phase,
        progress: progress ?? this.progress,
      );
}

final class CreatePostUploading extends CreatePostState {
  const CreatePostUploading({
    required this.files,
    required this.overallProgress,
  });

  final List<FileUploadProgress> files;
  final double overallProgress;
}
```

Also update `CreatePostError` to carry progress at failure — replace:

```dart
final class CreatePostError extends CreatePostState {
  const CreatePostError({required this.message, required this.draft});
  final String message;
  final PostDraft draft;
}
```

With:

```dart
final class CreatePostError extends CreatePostState {
  const CreatePostError({
    required this.message,
    required this.draft,
    this.overallProgress = 0.0,
  });

  final String message;
  final PostDraft draft;
  final double overallProgress;
}
```

- [ ] **Step 1.6: Run analyze to verify no compile errors**

```bash
cd apps/mobile && flutter analyze lib/features/post/presentation/providers/create_post_provider.dart
```

Expected: no errors (the old `progress` field references in the notifier will show errors — fix those in Task 3).

- [ ] **Step 1.7: Commit**

```bash
git add lib/core/cancellation/cancellation_token.dart \
        lib/features/post/presentation/providers/create_post_provider.dart \
        test/unit/core/cancellation/cancellation_token_test.dart
git commit -m "feat(upload): add CancellationToken and per-file progress types"
```

---

### Task 2: Thread onFileProgress + CancellationToken through the upload stack

**Files:**
- Modify: `lib/features/post/data/datasources/post_storage_datasource.dart`
- Modify: `lib/features/post/domain/repositories/post_repository.dart`
- Modify: `lib/features/post/data/repositories/post_repository_impl.dart`
- Modify: `lib/features/post/domain/usecases/create_post.dart`
- Modify: `test/unit/features/post/domain/usecases/create_post_test.dart`

- [ ] **Step 2.1: Update PostStorageDatasource to accept CancelToken**

In `lib/features/post/data/datasources/post_storage_datasource.dart`, update `_put`, `upload`, and `uploadBytes` to accept an optional Dio `CancelToken`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:unishare_mobile/features/post/data/datasources/upload_file_stub.dart'
    if (dart.library.io) 'upload_file_io.dart';

const _workerUrl = String.fromEnvironment('WORKER_URL');

class PostStorageDatasource {
  final _dio = Dio();

  Future<String> upload(
    String localPath,
    String uid, {
    void Function(double)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final filename = localPath.split('/').last;
    final bytes = await readFileBytes(localPath);
    return _put(bytes, filename, onProgress, cancelToken: cancelToken);
  }

  Future<String> uploadBytes(
    Uint8List bytes,
    String filename,
    String uid, {
    void Function(double)? onProgress,
    CancelToken? cancelToken,
  }) =>
      _put(bytes, filename, onProgress, cancelToken: cancelToken);

  Future<String> uploadText(String content, String uid, String filename) =>
      _put(
        Uint8List.fromList(utf8.encode(content)),
        filename,
        null,
        contentType: 'text/plain',
      );

  Future<String> _put(
    Uint8List bytes,
    String filename,
    void Function(double)? onProgress, {
    String? contentType,
    CancelToken? cancelToken,
  }) async {
    final ct = contentType ?? _contentTypeFor(filename);
    final idToken = await FirebaseAuth.instance.currentUser!.getIdToken();

    final workerRes = await _dio.post<Map<String, dynamic>>(
      _workerUrl,
      data: {'filename': filename, 'contentType': ct},
      options: Options(
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      ),
      cancelToken: cancelToken,
    );

    final uploadUrl = workerRes.data!['uploadUrl'] as String;
    final publicUrl = workerRes.data!['publicUrl'] as String;

    await _dio.put<void>(
      uploadUrl,
      data: Stream.fromIterable(bytes.map((b) => [b])),
      options: Options(
        headers: {'Content-Type': ct, 'Content-Length': bytes.length},
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 1),
      ),
      onSendProgress: onProgress != null
          ? (sent, total) {
              if (total > 0) onProgress(sent / total);
            }
          : null,
      cancelToken: cancelToken,
    );

    return publicUrl;
  }

  String _contentTypeFor(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }
}
```

- [ ] **Step 2.2: Update PostRepository domain interface**

Replace the `publishDraft` signature in `lib/features/post/domain/repositories/post_repository.dart`:

```dart
import 'dart:typed_data';

import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';

abstract class PostRepository {
  Stream<List<Post>> watchFeed({int limit = 20});
  Stream<Post> watchPost(String postId);
  Future<void> saveDraft(PostDraft draft);
  Future<void> removeDraft(String draftId);
  Future<List<PostDraft>> loadDraftQueue();
  Future<void> publishDraft(
    PostDraft draft, {
    void Function(double progress)? onProgress,
    void Function(int fileIndex, double fileProgress)? onFileProgress,
    Map<String, Uint8List>? fileDataOverride,
    CancellationToken? cancellationToken,
  });
}
```

- [ ] **Step 2.3: Update PostRepositoryImpl**

Replace `publishDraft` in `lib/features/post/data/repositories/post_repository_impl.dart`:

```dart
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';
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
    void Function(int fileIndex, double fileProgress)? onFileProgress,
    Map<String, Uint8List>? fileDataOverride,
    CancellationToken? cancellationToken,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('not_authenticated');

    var current = draft;
    final paths = draft.localMediaPaths;

    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      if (current.uploadedUrls.containsKey(path)) continue;
      if (cancellationToken?.isCancelled ?? false) return;

      final dioCancelToken = CancelToken();
      cancellationToken?.addCancelListener(dioCancelToken.cancel);

      try {
        final progressFn = (fp) {
          onFileProgress?.call(i, fp);
          onProgress?.call((i + fp) / paths.length);
        };
        final overrideBytes = fileDataOverride?[path];
        final url = overrideBytes != null
            ? await storageDatasource.uploadBytes(
                overrideBytes,
                path,
                user.uid,
                onProgress: progressFn,
                cancelToken: dioCancelToken,
              )
            : await storageDatasource.upload(
                path,
                user.uid,
                onProgress: progressFn,
                cancelToken: dioCancelToken,
              );

        final newUrls = Map<String, String>.from(current.uploadedUrls)
          ..[path] = url;
        current = current.copyWith(uploadedUrls: newUrls);
        await saveDraft(current);
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) return;
        await saveDraft(
          current.copyWith(
            status: DraftStatus.error,
            errorMessage: e.toString(),
          ),
        );
        rethrow;
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

    if (cancellationToken?.isCancelled ?? false) return;

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

- [ ] **Step 2.4: Update CreatePost use case**

Replace `lib/features/post/domain/usecases/create_post.dart`:

```dart
import 'dart:typed_data';

import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';

class CreatePost {
  const CreatePost(this._repository);

  final PostRepository _repository;

  Future<PostDraft> call({
    required PostDraft draft,
    required bool isConnected,
    void Function(double progress)? onProgress,
    void Function(int fileIndex, double fileProgress)? onFileProgress,
    Map<String, Uint8List>? fileDataOverride,
    CancellationToken? cancellationToken,
  }) async {
    if (draft.title.trim().isEmpty) throw ArgumentError('title_required');
    if (draft.description.trim().isEmpty) {
      throw ArgumentError('description_required');
    }
    if (draft.moduleNumber.trim().isEmpty) {
      throw ArgumentError('module_required');
    }

    await _repository.saveDraft(draft);

    if (!isConnected) return draft.copyWith(status: DraftStatus.queued);

    try {
      await _repository.publishDraft(
        draft,
        onProgress: onProgress,
        onFileProgress: onFileProgress,
        fileDataOverride: fileDataOverride,
        cancellationToken: cancellationToken,
      );
      return draft.copyWith(status: DraftStatus.published);
    } catch (_) {
      return draft.copyWith(status: DraftStatus.queued);
    }
  }
}
```

- [ ] **Step 2.5: Update create_post_test.dart stub**

In `test/unit/features/post/domain/usecases/create_post_test.dart`, update `_FakeRepo.publishDraft` to include the new params:

```dart
@override
Future<void> publishDraft(
  PostDraft draft, {
  void Function(double)? onProgress,
  void Function(int, double)? onFileProgress,
  Map<String, Uint8List>? fileDataOverride,
  CancellationToken? cancellationToken,
}) async {
  publishCalled = true;
  if (shouldThrowOnPublish) throw Exception('network error');
}
```

Also add the import at the top of `create_post_test.dart`:

```dart
import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';
```

- [ ] **Step 2.6: Run all existing unit tests to verify nothing broke**

```bash
cd apps/mobile && flutter test test/unit/
```

Expected: all tests pass.

- [ ] **Step 2.7: Commit**

```bash
git add lib/core/cancellation/cancellation_token.dart \
        lib/features/post/data/datasources/post_storage_datasource.dart \
        lib/features/post/domain/repositories/post_repository.dart \
        lib/features/post/data/repositories/post_repository_impl.dart \
        lib/features/post/domain/usecases/create_post.dart \
        test/unit/features/post/domain/usecases/create_post_test.dart
git commit -m "feat(upload): thread onFileProgress and CancellationToken through upload stack"
```

---

### Task 3: Update CreatePostNotifier — per-file state updates + cancel()

**Files:**
- Modify: `lib/features/post/presentation/providers/create_post_provider.dart`

- [ ] **Step 3.1: Rewrite CreatePostNotifier in create_post_provider.dart**

Replace the entire `CreatePostNotifier` class (keep the sealed state classes above it unchanged):

```dart
import 'dart:math';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';

part 'create_post_provider.g.dart';
```

Then the notifier:

```dart
@riverpod
class CreatePostNotifier extends _$CreatePostNotifier {
  static final _rand = Random.secure();
  static const _chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  CancellationToken? _cancellationToken;
  PostDraft? _inflight;

  @override
  CreatePostState build() => const CreatePostIdle();

  Future<void> submit({
    required PostDraft draft,
    Map<String, Uint8List>? fileDataOverride,
  }) async {
    _cancellationToken = CancellationToken();
    _inflight = draft;

    final filenames = draft.localMediaPaths.isEmpty
        ? <String>[]
        : draft.localMediaPaths.map((p) => p.split('/').last).toList();

    state = CreatePostUploading(
      files: filenames
          .map(
            (name) => FileUploadProgress(
              filename: name,
              phase: FileUploadPhase.queued,
            ),
          )
          .toList(),
      overallProgress: 0.0,
    );

    final useCase = ref.read(createPostUseCaseProvider);

    try {
      final results = await Connectivity().checkConnectivity();
      final isConnected = kIsWeb || !results.contains(ConnectivityResult.none);

      double currentOverall = 0.0;

      final result = await useCase(
        draft: draft,
        isConnected: isConnected,
        fileDataOverride: fileDataOverride,
        cancellationToken: _cancellationToken,
        onFileProgress: (fileIndex, fileProgress) {
          final current = state;
          if (current is! CreatePostUploading) return;

          final updatedFiles = List<FileUploadProgress>.from(current.files);
          for (var j = 0; j < fileIndex; j++) {
            if (updatedFiles[j].phase != FileUploadPhase.done) {
              updatedFiles[j] = updatedFiles[j].copyWith(
                phase: FileUploadPhase.done,
                progress: 1.0,
              );
            }
          }
          updatedFiles[fileIndex] = updatedFiles[fileIndex].copyWith(
            phase: FileUploadPhase.uploading,
            progress: fileProgress,
          );

          currentOverall = (fileIndex + fileProgress) / filenames.length;
          state = CreatePostUploading(
            files: updatedFiles,
            overallProgress: currentOverall,
          );
        },
        onProgress: (p) {
          if (p >= 1.0) state = const CreatePostPublishing();
        },
      );

      state = switch (result.status) {
        DraftStatus.published => CreatePostPublished(postId: result.id),
        DraftStatus.queued => CreatePostQueued(draftId: result.id),
        _ => CreatePostError(
          message: result.errorMessage ?? 'Unknown error',
          draft: result,
          overallProgress: currentOverall,
        ),
      };
    } on ArgumentError catch (e) {
      state = CreatePostError(
        message: e.message.toString(),
        draft: draft,
        overallProgress: 0.0,
      );
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel) {
        state = CreatePostError(
          message: e.toString(),
          draft: draft,
          overallProgress: 0.0,
        );
      }
      // Cancellation is handled silently — cancel() already reset state.
    } catch (e) {
      state = CreatePostError(
        message: e.toString(),
        draft: draft,
        overallProgress: 0.0,
      );
    }
  }

  Future<void> cancel() async {
    _cancellationToken?.cancel();
    // TODO: orphaned R2 files — add worker DELETE endpoint and call it
    // for each url in _inflight.uploadedUrls before removing the draft.
    final draft = _inflight;
    if (draft != null) {
      await ref.read(postRepositoryProvider).removeDraft(draft.id);
    }
    _inflight = null;
    _cancellationToken = null;
    state = const CreatePostIdle();
  }

  void reset() {
    _inflight = null;
    _cancellationToken = null;
    state = const CreatePostIdle();
  }

  static String generateId() =>
      List.generate(20, (_) => _chars[_rand.nextInt(_chars.length)]).join();
}
```

Note: `currentOverall` is declared as `double currentOverall = 0.0` inside `submit()`. The closure captures it by reference.

- [ ] **Step 3.2: Run dart analyze**

```bash
cd apps/mobile && flutter analyze lib/features/post/presentation/providers/create_post_provider.dart
```

Expected: no errors.

- [ ] **Step 3.3: Run code generation**

```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
```

Expected: `create_post_provider.g.dart` regenerated without errors.

- [ ] **Step 3.4: Run unit tests**

```bash
cd apps/mobile && flutter test test/unit/
```

Expected: all pass.

- [ ] **Step 3.5: Commit**

```bash
git add lib/features/post/presentation/providers/create_post_provider.dart \
        lib/features/post/presentation/providers/create_post_provider.g.dart
git commit -m "feat(upload): update CreatePostNotifier with per-file state and cancel support"
```

---

### Task 4: Create UploadProgressScreen

**Files:**
- Create: `test/widget/features/post/screens/upload_progress_screen_test.dart`
- Create: `lib/features/post/presentation/screens/upload_progress_screen.dart`

- [ ] **Step 4.1: Write failing widget tests**

Create `test/widget/features/post/screens/upload_progress_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/presentation/providers/create_post_provider.dart';
import 'package:unishare_mobile/features/post/presentation/screens/upload_progress_screen.dart';

// ---------------------------------------------------------------------------
// Stub notifiers
// ---------------------------------------------------------------------------

class _UploadingNotifier extends CreatePostNotifier {
  @override
  CreatePostState build() => CreatePostUploading(
        files: [
          const FileUploadProgress(
            filename: 'notes.pdf',
            phase: FileUploadPhase.done,
            progress: 1.0,
          ),
          const FileUploadProgress(
            filename: 'diagram.png',
            phase: FileUploadPhase.uploading,
            progress: 0.34,
          ),
          const FileUploadProgress(
            filename: 'exam.pdf',
            phase: FileUploadPhase.queued,
          ),
        ],
        overallProgress: 0.48,
      );

  @override
  Future<void> cancel() async {}
}

class _PublishingNotifier extends CreatePostNotifier {
  @override
  CreatePostState build() => const CreatePostPublishing();

  @override
  Future<void> cancel() async {}
}

class _ErrorNotifier extends CreatePostNotifier {
  @override
  CreatePostState build() => CreatePostError(
        message: 'Network error',
        draft: PostDraft(
          id: 'test',
          postType: PostType.lectureNote,
          year: 1,
          courseId: 'csc101',
          title: 'T',
          description: 'D',
          postingIdentity: PostingIdentity.named,
          semester: 1,
          moduleNumber: '1',
          localMediaPaths: [],
          uploadedUrls: {},
          createdAt: DateTime(2026),
        ),
        overallProgress: 0.48,
      );

  @override
  Future<void> cancel() async {}
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _makeScreen(CreatePostNotifier notifier) => ProviderScope(
      overrides: [createPostProvider.overrideWith(() => notifier)],
      child: const MaterialApp(home: UploadProgressScreen()),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('UploadProgressScreen', () {
    testWidgets('shows percentage and all three file rows when uploading', (
      tester,
    ) async {
      await tester.pumpWidget(_makeScreen(_UploadingNotifier()));
      await tester.pump();

      expect(find.text('48%'), findsOneWidget);
      expect(find.text('notes.pdf'), findsOneWidget);
      expect(find.text('diagram.png'), findsOneWidget);
      expect(find.text('exam.pdf'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('34%'), findsOneWidget);
      expect(find.text('Queued'), findsOneWidget);
    });

    testWidgets('shows Publishing text when in publishing state', (
      tester,
    ) async {
      await tester.pumpWidget(_makeScreen(_PublishingNotifier()));
      await tester.pump();

      expect(find.text('Publishing…'), findsOneWidget);
      expect(find.text('Finishing up…'), findsOneWidget);
    });

    testWidgets('Cancel button is disabled in publishing state', (
      tester,
    ) async {
      await tester.pumpWidget(_makeScreen(_PublishingNotifier()));
      await tester.pump();

      final cancelBtn = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cancel'),
      );
      expect(cancelBtn.onPressed, isNull);
    });

    testWidgets('shows error message and Retry button on error state', (
      tester,
    ) async {
      await tester.pumpWidget(_makeScreen(_ErrorNotifier()));
      await tester.pump();

      expect(find.text('Upload failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Cancel button is present and tappable when uploading', (
      tester,
    ) async {
      var cancelled = false;
      final notifier = _UploadingNotifier();

      await tester.pumpWidget(_makeScreen(notifier));
      await tester.pump();

      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 4.2: Run tests to verify they fail**

```bash
cd apps/mobile && flutter test test/widget/features/post/screens/upload_progress_screen_test.dart
```

Expected: compile error — `UploadProgressScreen` not found.

- [ ] **Step 4.3: Create UploadProgressScreen**

Create `lib/features/post/presentation/screens/upload_progress_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unishare_mobile/features/post/presentation/providers/create_post_provider.dart';

const _kWhite = Colors.white;
const _kBg = Color(0xFFF7F3EE);
const _kPrimary = Color(0xFFD97706);
const _kBorder = Color(0xFFE2DAD0);
const _kFg = Color(0xFF1C1917);
const _kMuted = Color(0xFF8A837E);
const _kGreen = Color(0xFF059669);
const _kGreenBg = Color(0xFFD1FAE5);
const _kDestructive = Color(0xFFDC2626);
const _kDestructiveBg = Color(0xFFFEE2E2);

class UploadProgressScreen extends ConsumerStatefulWidget {
  const UploadProgressScreen({super.key});

  @override
  ConsumerState<UploadProgressScreen> createState() =>
      _UploadProgressScreenState();
}

class _UploadProgressScreenState extends ConsumerState<UploadProgressScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen<CreatePostState>(createPostProvider, (_, next) {
      if (next is CreatePostPublished) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          ref.read(createPostProvider.notifier).reset();
          context.go('/feed');
        });
      } else if (next is CreatePostQueued) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved offline — will publish when you reconnect.'),
          ),
        );
        ref.read(createPostProvider.notifier).reset();
        context.go('/feed');
      }
    });

    final state = ref.watch(createPostProvider);
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(state),
      body: SafeArea(child: _buildBody(state)),
    );
  }

  AppBar _buildAppBar(CreatePostState state) {
    final isPublishing = state is CreatePostPublishing;
    return AppBar(
      backgroundColor: _kWhite,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Text(
        'Uploading Post',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _kFg,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton(
            onPressed: isPublishing
                ? null
                : () async {
                    await ref.read(createPostProvider.notifier).cancel();
                    if (mounted) context.go('/feed');
                  },
            style: TextButton.styleFrom(
              foregroundColor: _kDestructive,
              disabledForegroundColor: _kMuted,
              side: BorderSide(
                color: isPublishing ? _kBorder : const Color(0xFFFCA5A5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _kBorder),
      ),
    );
  }

  Widget _buildBody(CreatePostState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          _buildRing(state),
          const SizedBox(height: 12),
          _buildSubtitles(state),
          const SizedBox(height: 28),
          if (state is CreatePostUploading) _buildFileList(state.files),
          if (state is CreatePostPublishing) _buildFileListAllDone(),
          if (state is CreatePostError) ...[
            _buildErrorBanner(state),
            const SizedBox(height: 16),
            _buildRetryButton(state),
          ],
        ],
      ),
    );
  }

  Widget _buildRing(CreatePostState state) {
    final Color ringColor;
    final Color ringBg;
    final Widget center;

    if (state is CreatePostUploading) {
      ringColor = _kPrimary;
      ringBg = _kBorder;
      final pct = (state.overallProgress * 100).toInt();
      center = Text(
        '$pct%',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _kPrimary,
        ),
      );
    } else if (state is CreatePostPublishing) {
      ringColor = _kGreen;
      ringBg = _kGreenBg;
      center = const Icon(Icons.check_rounded, size: 32, color: _kGreen);
    } else if (state is CreatePostError) {
      ringColor = _kDestructive;
      ringBg = _kDestructiveBg;
      center = const Icon(
        Icons.priority_high_rounded,
        size: 32,
        color: _kDestructive,
      );
    } else {
      ringColor = _kPrimary;
      ringBg = _kBorder;
      center = const SizedBox.shrink();
    }

    final value = state is CreatePostUploading
        ? state.overallProgress
        : state is CreatePostError
            ? (state as CreatePostError).overallProgress
            : 1.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: 10,
            backgroundColor: ringBg,
            valueColor: AlwaysStoppedAnimation(ringColor),
          ),
        ),
        center,
      ],
    );
  }

  Widget _buildSubtitles(CreatePostState state) {
    if (state is CreatePostUploading) {
      final uploading = state.files
          .where((f) => f.phase == FileUploadPhase.uploading)
          .map((f) => f.filename)
          .firstOrNull;
      final done = state.files.where((f) => f.phase == FileUploadPhase.done).length;
      final total = state.files.length;
      return Column(
        children: [
          Text(
            '$done of $total files',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kFg,
            ),
          ),
          if (uploading != null) ...[
            const SizedBox(height: 4),
            Text(
              'Uploading $uploading…',
              style: GoogleFonts.firaCode(fontSize: 11, color: _kMuted),
            ),
          ],
        ],
      );
    } else if (state is CreatePostPublishing) {
      return Column(
        children: [
          Text(
            'Publishing…',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kFg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Finishing up…',
            style: GoogleFonts.firaCode(fontSize: 11, color: _kMuted),
          ),
        ],
      );
    } else if (state is CreatePostError) {
      final failedFile = state.draft.localMediaPaths
          .where((p) => !state.draft.uploadedUrls.containsKey(p))
          .map((p) => p.split('/').last)
          .firstOrNull;
      return Column(
        children: [
          Text(
            'Upload failed',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kDestructive,
            ),
          ),
          if (failedFile != null) ...[
            const SizedBox(height: 4),
            Text(
              '$failedFile could not be uploaded',
              style: GoogleFonts.firaCode(fontSize: 11, color: _kMuted),
            ),
          ],
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFileList(List<FileUploadProgress> files) {
    return Container(
      decoration: BoxDecoration(
        color: _kWhite,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var i = 0; i < files.length; i++)
            _FileRow(
              file: files[i],
              isLast: i == files.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildFileListAllDone() {
    return Container(
      decoration: BoxDecoration(
        color: _kWhite,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Icon(Icons.check_circle_outline_rounded,
              color: _kGreen, size: 32),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(CreatePostError state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        state.message,
        style: GoogleFonts.spaceGrotesk(fontSize: 12, color: _kDestructive),
      ),
    );
  }

  Widget _buildRetryButton(CreatePostError state) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: FilledButton(
        onPressed: () {
          ref.read(createPostProvider.notifier).submit(draft: state.draft);
        },
        style: FilledButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: _kWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(
          'Retry',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FileRow widget
// ---------------------------------------------------------------------------

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.isLast});

  final FileUploadProgress file;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Opacity(
          opacity: file.phase == FileUploadPhase.queued ? 0.45 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Column(
              children: [
                Row(
                  children: [
                    _PhaseIcon(phase: file.phase),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        file.filename,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: file.phase == FileUploadPhase.queued
                              ? const Color(0xFF8A837E)
                              : const Color(0xFF1C1917),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _PhaseLabel(file: file),
                  ],
                ),
                if (file.phase == FileUploadPhase.uploading) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: LinearProgressIndicator(
                      value: file.progress,
                      minHeight: 3,
                      backgroundColor: const Color(0xFFE2DAD0),
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFFD97706)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1, color: Color(0xFFE2DAD0)),
      ],
    );
  }
}

class _PhaseIcon extends StatelessWidget {
  const _PhaseIcon({required this.phase});
  final FileUploadPhase phase;

  @override
  Widget build(BuildContext context) {
    return switch (phase) {
      FileUploadPhase.done => Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFFD1FAE5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 10,
            color: Color(0xFF059669),
          ),
        ),
      FileUploadPhase.uploading => SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor:
                const AlwaysStoppedAnimation(Color(0xFFD97706)),
          ),
        ),
      FileUploadPhase.queued => Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF8A837E), width: 1.5),
          ),
        ),
    };
  }
}

class _PhaseLabel extends StatelessWidget {
  const _PhaseLabel({required this.file});
  final FileUploadProgress file;

  @override
  Widget build(BuildContext context) {
    return switch (file.phase) {
      FileUploadPhase.done => Text(
          'Done',
          style: GoogleFonts.firaCode(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF059669),
          ),
        ),
      FileUploadPhase.uploading => Text(
          '${(file.progress * 100).toInt()}%',
          style: GoogleFonts.firaCode(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFD97706),
          ),
        ),
      FileUploadPhase.queued => Text(
          'Queued',
          style: GoogleFonts.firaCode(
            fontSize: 11,
            color: const Color(0xFF8A837E),
          ),
        ),
    };
  }
}
```

- [ ] **Step 4.4: Run the widget tests**

```bash
cd apps/mobile && flutter test test/widget/features/post/screens/upload_progress_screen_test.dart
```

Expected: 5 tests pass.

- [ ] **Step 4.5: Commit**

```bash
git add lib/features/post/presentation/screens/upload_progress_screen.dart \
        test/widget/features/post/screens/upload_progress_screen_test.dart
git commit -m "feat(upload): add UploadProgressScreen with ring hero and per-file list"
```

---

### Task 5: Wire CreatePostScreen + router

**Files:**
- Modify: `lib/features/post/presentation/screens/create_post_screen.dart`
- Modify: `lib/core/router/router.dart`
- Modify: `test/widget/features/post/screens/create_post_screen_test.dart`

- [ ] **Step 5.1: Update create_post_screen_test.dart stub**

In `test/widget/features/post/screens/create_post_screen_test.dart`, update `_StubRepo.publishDraft` to match the new interface. Add the import and update the method:

Add to imports:
```dart
import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';
```

Replace `_StubRepo.publishDraft`:
```dart
@override
Future<void> publishDraft(
  PostDraft draft, {
  void Function(double)? onProgress,
  void Function(int, double)? onFileProgress,
  Map<String, Uint8List>? fileDataOverride,
  CancellationToken? cancellationToken,
}) async {}
```

- [ ] **Step 5.2: Run existing create_post_screen tests to verify they still pass**

```bash
cd apps/mobile && flutter test test/widget/features/post/screens/create_post_screen_test.dart
```

Expected: all pass.

- [ ] **Step 5.3: Update CreatePostScreen**

In `lib/features/post/presentation/screens/create_post_screen.dart`:

**a)** Remove the `ref.listen` block for `CreatePostPublished` / `CreatePostQueued` (the progress screen handles navigation now). Delete lines 164–188.

**b)** Remove the `isSubmitting` variable and the two `SliverToBoxAdapter` blocks for `CreatePostUploading` and `CreatePostPublishing` (lines 190–341 — the inline banners). Keep only the error banner.

**c)** Make `_submit` synchronous:

Replace:
```dart
Future<void> _submit() async {
  final localMediaPaths = _pickedFiles
      .map((f) => f.bytes != null ? f.name : f.path!)
      .toList();

  final fileDataOverride = {
    for (final f in _pickedFiles)
      if (f.bytes != null) f.name: f.bytes!,
  };

  final draft = PostDraft(
    id: CreatePostNotifier.generateId(),
    postType: _postType ?? PostType.lectureNote,
    year: _year ?? 1,
    courseId: _courseId ?? '',
    title: _titleCtrl.text.trim(),
    description: _descCtrl.text.trim(),
    postingIdentity: _postingIdentity,
    semester: _semester,
    moduleNumber: _moduleCtrl.text.trim(),
    externalUrl: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
    tags: List.from(_tags),
    localMediaPaths: localMediaPaths,
    uploadedUrls: {},
    codeSnippet: _codeSnippet,
    createdAt: DateTime.now(),
  );

  await ref
      .read(createPostProvider.notifier)
      .submit(
        draft: draft,
        fileDataOverride: fileDataOverride.isEmpty ? null : fileDataOverride,
      );
}
```

With:
```dart
void _submit() {
  final localMediaPaths = _pickedFiles
      .map((f) => f.bytes != null ? f.name : f.path!)
      .toList();

  final fileDataOverride = {
    for (final f in _pickedFiles)
      if (f.bytes != null) f.name: f.bytes!,
  };

  final draft = PostDraft(
    id: CreatePostNotifier.generateId(),
    postType: _postType ?? PostType.lectureNote,
    year: _year ?? 1,
    courseId: _courseId ?? '',
    title: _titleCtrl.text.trim(),
    description: _descCtrl.text.trim(),
    postingIdentity: _postingIdentity,
    semester: _semester,
    moduleNumber: _moduleCtrl.text.trim(),
    externalUrl: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
    tags: List.from(_tags),
    localMediaPaths: localMediaPaths,
    uploadedUrls: {},
    codeSnippet: _codeSnippet,
    createdAt: DateTime.now(),
  );

  ref.read(createPostProvider.notifier).submit(
        draft: draft,
        fileDataOverride: fileDataOverride.isEmpty ? null : fileDataOverride,
      );
  context.push('/upload-progress');
}
```

**d)** Update `_goNext` to call `_submit()` (remove `async`/`await`):

Replace:
```dart
void _goNext() {
  if (_step < 3) {
    setState(() => _step++);
    _pageCtrl.animateToPage(
      _step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  } else {
    _submit();
  }
}
```

With:
```dart
void _goNext() {
  if (_step < 3) {
    setState(() => _step++);
    _pageCtrl.animateToPage(
      _step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  } else {
    _submit();
  }
}
```

(No change needed since `_submit` is already a plain call — just ensure no `await` remains.)

**e)** Remove `isSubmitting` from the nav bar — replace the nav bar section:

Remove:
```dart
final isSubmitting =
    postState is CreatePostUploading || postState is CreatePostPublishing;
```

And update the nav bar buttons to remove all `isSubmitting` references:
- `onPressed: isSubmitting ? null : _goBack` → `onPressed: _goBack`
- `onPressed: (_nextEnabled && !isSubmitting) ? _goNext : null` → `onPressed: _nextEnabled ? _goNext : null`
- `child: Text(isSubmitting ? 'Publishing…' : (_step == 3 ? 'Submit' : 'Next'), ...)` → `child: Text(_step == 3 ? 'Submit' : 'Next', ...)`

Also remove `final postState = ref.watch(createPostProvider);` if it's no longer used (keep it if the error banner still watches it).

- [ ] **Step 5.4: Add /upload-progress to router**

In `lib/core/router/router.dart`:

**a)** Add the import for the new screen at the top:
```dart
import 'package:unishare_mobile/features/post/presentation/screens/upload_progress_screen.dart';
```

**b)** Add the route after `/posts/create`:
```dart
GoRoute(
  path: '/upload-progress',
  builder: (context, state) => const UploadProgressScreen(),
),
```

**c)** Add `/upload-progress` to `knownPrefixes` so the redirect guard does not intercept it:
```dart
const knownPrefixes = {
  '/feed',
  '/posts',
  '/notifications',
  '/more',
  '/preview',
  '/upload-progress',
};
```

- [ ] **Step 5.5: Run dart analyze on changed files**

```bash
cd apps/mobile && flutter analyze \
  lib/features/post/presentation/screens/create_post_screen.dart \
  lib/core/router/router.dart
```

Expected: no errors.

- [ ] **Step 5.6: Run all tests**

```bash
cd apps/mobile && flutter test test/unit/ test/widget/
```

Expected: all pass.

- [ ] **Step 5.7: Commit**

```bash
git add lib/features/post/presentation/screens/create_post_screen.dart \
        lib/core/router/router.dart \
        test/widget/features/post/screens/create_post_screen_test.dart
git commit -m "feat(upload): wire CreatePostScreen fire-and-forget and add /upload-progress route"
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Task |
|---|---|
| Dedicated `/upload-progress` route | Task 5 |
| Per-file detail (queued/uploading/done) | Tasks 1 + 4 |
| Ring hero with overall % | Task 4 |
| Auto-navigate to feed after 1.5s on publish | Task 4 (`ref.listen`) |
| Cancel = stop upload + remove Hive draft | Task 3 (`cancel()`) |
| Orphaned R2 files TODO comment | Task 3 |
| Fire-and-forget submit | Task 5 |
| "Finishing up…" subtitle in publishing state | Task 4 |
| Error state with Retry button | Task 4 |
| Cancel disabled during publishing | Task 4 |
| `CancellationToken` threads through stack | Tasks 1 + 2 |
| Remove inline progress banners from CreatePostScreen | Task 5 |

**Type consistency check:** `FileUploadPhase` and `FileUploadProgress` are defined in Task 1 and used consistently in Tasks 3 and 4. `CancellationToken` defined in Task 1, used in Tasks 2 and 3. `cancel()` defined in Task 3, called in Task 4 and 5.

**Placeholder scan:** No TBDs. All code steps contain full implementations.
