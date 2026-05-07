import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';
import 'package:unishare_mobile/features/post/domain/usecases/create_post.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeRepo implements PostRepository {
  final _savedDrafts = <String, PostDraft>{};
  bool publishCalled = false;
  bool shouldThrowOnPublish = false;

  @override
  Stream<List<Post>> watchFeed({int limit = 20}) => throw UnimplementedError();

  @override
  Stream<Post> watchPost(String postId) => throw UnimplementedError();

  @override
  Future<void> saveDraft(PostDraft draft) async {
    _savedDrafts[draft.id] = draft;
  }

  @override
  Future<void> removeDraft(String draftId) async {
    _savedDrafts.remove(draftId);
  }

  @override
  Future<List<PostDraft>> loadDraftQueue() async =>
      _savedDrafts.values.toList();

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
}

// ---------------------------------------------------------------------------
// Helper to build a valid draft
// ---------------------------------------------------------------------------

PostDraft _validDraft({
  List<String> localMediaPaths = const [],
  String title = 'Test Title',
  String description = 'Test description',
  String moduleNumber = '3',
}) {
  return PostDraft(
    id: 'test-id',
    postType: PostType.lectureNote,
    year: 2,
    courseId: 'csc201',
    title: title,
    description: description,
    postingIdentity: PostingIdentity.named,
    semester: 1,
    moduleNumber: moduleNumber,
    localMediaPaths: localMediaPaths,
    uploadedUrls: {},
    createdAt: DateTime(2026, 5, 5),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeRepo repo;
  late CreatePost useCase;

  setUp(() {
    repo = _FakeRepo();
    useCase = CreatePost(repo);
  });

  group('validation', () {
    test('throws title_required when title is empty', () async {
      expect(
        () => useCase(draft: _validDraft(title: '   '), isConnected: true),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'title_required',
          ),
        ),
      );
    });

    test('throws description_required when description is empty', () async {
      expect(
        () => useCase(draft: _validDraft(description: ''), isConnected: true),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'description_required',
          ),
        ),
      );
    });

    test('throws module_required when moduleNumber is empty', () async {
      expect(
        () => useCase(draft: _validDraft(moduleNumber: ''), isConnected: true),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'module_required',
          ),
        ),
      );
    });

    test('small file passes size check and is published', () async {
      final tmpDir = Directory.systemTemp;
      final smallFile = File('${tmpDir.path}/test_small.bin');
      smallFile.writeAsBytesSync([0]);

      final result = await useCase(
        draft: _validDraft(localMediaPaths: [smallFile.path]),
        isConnected: true,
      );

      expect(result.status, DraftStatus.published);
      smallFile.deleteSync();
    });
  });

  group('connectivity handling', () {
    test('returns queued status when offline', () async {
      final result = await useCase(draft: _validDraft(), isConnected: false);
      expect(result.status, DraftStatus.queued);
      expect(repo.publishCalled, isFalse);
    });

    test('returns published status when online and publish succeeds', () async {
      final result = await useCase(draft: _validDraft(), isConnected: true);
      expect(result.status, DraftStatus.published);
      expect(repo.publishCalled, isTrue);
    });

    test('returns queued status when online but publish throws', () async {
      repo.shouldThrowOnPublish = true;
      final result = await useCase(draft: _validDraft(), isConnected: true);
      expect(result.status, DraftStatus.queued);
    });
  });

  group('draft persistence', () {
    test('saves draft to queue before attempting publish', () async {
      await useCase(draft: _validDraft(), isConnected: false);
      expect(repo._savedDrafts, contains('test-id'));
    });
  });
}
