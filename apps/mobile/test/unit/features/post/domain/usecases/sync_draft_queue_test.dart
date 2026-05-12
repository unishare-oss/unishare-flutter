import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';
import 'package:unishare_mobile/features/post/domain/usecases/sync_draft_queue.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeRepo implements PostRepository {
  final List<PostDraft> queue;
  final Set<String> published = {};
  String? failOnId;

  _FakeRepo(this.queue);

  @override
  Stream<List<Post>> watchFeed({int limit = 20}) => throw UnimplementedError();

  @override
  Stream<Post> watchPost(String postId) => throw UnimplementedError();

  @override
  Stream<List<Post>> watchPostsByAuthor(String authorId, {int limit = 50}) =>
      throw UnimplementedError();

  @override
  Future<void> saveDraft(PostDraft draft) async {}

  @override
  Future<void> removeDraft(String draftId) async {
    queue.removeWhere((d) => d.id == draftId);
  }

  @override
  Future<List<PostDraft>> loadDraftQueue() async => List.from(queue);

  @override
  Future<void> publishDraft(
    PostDraft draft, {
    void Function(double)? onProgress,
    void Function(int, double)? onFileProgress,
    void Function(PostDraft)? onDraftUpdated,
    Map<String, Uint8List>? fileDataOverride,
    CancellationToken? cancellationToken,
  }) async {
    if (draft.id == failOnId) throw Exception('publish failed');
    published.add(draft.id);
  }
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

PostDraft _draft(String id, {DraftStatus status = DraftStatus.queued}) {
  return PostDraft(
    id: id,
    postType: PostType.lectureNote,
    year: 1,
    courseId: 'csc101',
    departmentId: 'dept-cs',
    title: 'Title $id',
    description: 'Desc',
    postingIdentity: PostingIdentity.named,
    semester: 1,
    moduleNumber: '1',
    localMediaPaths: [],
    uploadedUrls: {},
    createdAt: DateTime(2026, 5, 5),
    status: status,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SyncDraftQueue', () {
    test('emits nothing when queue is empty', () async {
      final repo = _FakeRepo([]);
      final useCase = SyncDraftQueue(repo);
      final emitted = await useCase().toList();
      expect(emitted, isEmpty);
    });

    test(
      'publishes a single queued draft and emits published status',
      () async {
        final draft = _draft('d1');
        final repo = _FakeRepo([draft]);
        final useCase = SyncDraftQueue(repo);

        final emitted = await useCase().toList();

        expect(emitted.length, 1);
        expect(emitted.first.status, DraftStatus.published);
        expect(repo.published, contains('d1'));
      },
    );

    test('skips already-published drafts', () async {
      final draft = _draft('d1', status: DraftStatus.published);
      final repo = _FakeRepo([draft]);
      final useCase = SyncDraftQueue(repo);

      final emitted = await useCase().toList();
      expect(emitted, isEmpty);
      expect(repo.published, isEmpty);
    });

    test('stops on first failure and emits error status', () async {
      final d1 = _draft('d1');
      final d2 = _draft('d2');
      final repo = _FakeRepo([d1, d2]);
      repo.failOnId = 'd1';
      final useCase = SyncDraftQueue(repo);

      final emitted = await useCase().toList();

      expect(emitted.length, 1);
      expect(emitted.first.id, 'd1');
      expect(emitted.first.status, DraftStatus.error);
      // d2 should not have been attempted
      expect(repo.published, isNot(contains('d2')));
    });

    test('emits status transitions in order for multiple drafts', () async {
      final drafts = [_draft('a'), _draft('b'), _draft('c')];
      final repo = _FakeRepo(drafts);
      final useCase = SyncDraftQueue(repo);

      final emitted = await useCase().toList();
      expect(emitted.map((d) => d.id).toList(), ['a', 'b', 'c']);
      expect(emitted.every((d) => d.status == DraftStatus.published), isTrue);
    });
  });
}
