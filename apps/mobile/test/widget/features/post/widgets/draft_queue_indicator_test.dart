import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';
import 'package:unishare_mobile/features/post/domain/usecases/sync_draft_queue.dart';
import 'package:unishare_mobile/features/post/presentation/providers/draft_queue_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/draft_queue_indicator.dart';

// ---------------------------------------------------------------------------
// Stub
// ---------------------------------------------------------------------------

class _StubRepo implements PostRepository {
  @override
  Stream<List<Post>> watchFeed({int limit = 20}) => throw UnimplementedError();
  @override
  Future<void> saveDraft(PostDraft draft) async {}
  @override
  Future<void> removeDraft(String draftId) async {}
  @override
  Future<List<PostDraft>> loadDraftQueue() async => [];
  @override
  Future<void> publishDraft(
    PostDraft draft, {
    void Function(double)? onProgress,
  }) async {}
}

PostDraft _queuedDraft(String id) => PostDraft(
  id: id,
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
  createdAt: DateTime(2026, 5, 5),
  status: DraftStatus.queued,
);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(List<PostDraft> queue) {
  return ProviderScope(
    overrides: [
      postRepositoryProvider.overrideWithValue(_StubRepo()),
      syncDraftQueueUseCaseProvider.overrideWithValue(
        SyncDraftQueue(_StubRepo()),
      ),
      draftQueueProvider.overrideWith(() => _FakeNotifier(queue)),
    ],
    child: const MaterialApp(home: Scaffold(body: DraftQueueIndicator())),
  );
}

class _FakeNotifier extends DraftQueueNotifier {
  _FakeNotifier(this._queue);
  final List<PostDraft> _queue;

  @override
  List<PostDraft> build() => _queue;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DraftQueueIndicator', () {
    testWidgets('renders nothing when queue is empty', (tester) async {
      await tester.pumpWidget(_wrap([]));
      expect(find.byType(Container), findsNothing);
      expect(find.textContaining('queued'), findsNothing);
    });

    testWidgets('shows count when there are queued drafts', (tester) async {
      await tester.pumpWidget(_wrap([_queuedDraft('a'), _queuedDraft('b')]));
      await tester.pump();
      expect(find.text('2 queued'), findsOneWidget);
    });

    testWidgets('shows correct count for single draft', (tester) async {
      await tester.pumpWidget(_wrap([_queuedDraft('x')]));
      await tester.pump();
      expect(find.text('1 queued'), findsOneWidget);
    });
  });
}
