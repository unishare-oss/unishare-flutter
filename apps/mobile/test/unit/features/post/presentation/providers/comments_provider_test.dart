import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/domain/entities/comment.dart';
import 'package:unishare_mobile/features/post/domain/usecases/watch_comments.dart';
import 'package:unishare_mobile/features/post/presentation/providers/comments_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';

import '../../fakes/fake_comment_repository.dart';
import '../../fakes/post_factories.dart';

void main() {
  group('commentsProvider', () {
    test('emits AsyncLoading then AsyncData<List<Comment>>', () async {
      final repo = FakeCommentRepository();
      final watchComments = WatchComments(repo);

      final container = ProviderContainer(
        overrides: [
          watchCommentsUseCaseProvider.overrideWithValue(watchComments),
        ],
      );
      addTearDown(container.dispose);

      // Subscribe so the provider starts building.
      container.listen(commentsProvider('post-1'), (prev, next) {});

      // Before any stream event: loading.
      final initialState = container.read(commentsProvider('post-1'));
      expect(initialState, isA<AsyncLoading<List<Comment>>>());

      // Emit first batch and await the provider future to resolve.
      final comments = [fakeComment()];
      repo.controller.add(comments);

      // Await the stream provider to deliver the value.
      final value = await container.read(commentsProvider('post-1').future);

      expect(value, comments);

      final state = container.read(commentsProvider('post-1'));
      expect(state, isA<AsyncData<List<Comment>>>());
      expect((state as AsyncData<List<Comment>>).value, comments);

      await repo.controller.close();
    });

    test('updates on re-emit', () async {
      final repo = FakeCommentRepository();
      final watchComments = WatchComments(repo);

      final container = ProviderContainer(
        overrides: [
          watchCommentsUseCaseProvider.overrideWithValue(watchComments),
        ],
      );
      addTearDown(container.dispose);

      // Subscribe.
      container.listen(commentsProvider('post-1'), (prev, next) {});

      final firstBatch = [fakeComment(id: 'c-1')];
      repo.controller.add(firstBatch);
      await container.read(commentsProvider('post-1').future);

      final secondBatch = [fakeComment(id: 'c-1'), fakeComment(id: 'c-2')];
      repo.controller.add(secondBatch);
      // Flush microtasks for the second event.
      await Future<void>.value();
      await Future<void>.value();

      final state = container.read(commentsProvider('post-1'));
      expect(state, isA<AsyncData<List<Comment>>>());
      expect((state as AsyncData<List<Comment>>).value, hasLength(2));

      await repo.controller.close();
    });
  });
}
