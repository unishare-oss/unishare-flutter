import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/usecases/watch_post.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_detail_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';

import '../../fakes/fake_post_repository.dart';
import '../../fakes/post_factories.dart';

class _FakeWatchPost extends WatchPost {
  _FakeWatchPost(super.repo);
}

void main() {
  group('postDetailProvider — warm-start (seed provided)', () {
    test(
      'state is AsyncData(seed) immediately before stream arrives',
      () async {
        final repo = FakePostRepository();
        final watchPost = _FakeWatchPost(repo);

        final seed = fakePost(id: 'post-1');
        final container = ProviderContainer(
          overrides: [watchPostUseCaseProvider.overrideWithValue(watchPost)],
        );
        addTearDown(container.dispose);

        final initialState = container.read(
          postDetailProvider('post-1', seed: seed),
        );
        expect(initialState, isA<AsyncData<Post>>());
        expect((initialState as AsyncData<Post>).value, equals(seed));

        await repo.postController.close();
      },
    );

    test('state updates to AsyncData(newPost) after stream emits', () async {
      final repo = FakePostRepository();
      final watchPost = _FakeWatchPost(repo);

      final seed = fakePost(id: 'post-1');
      final updatedPost = fakePost(id: 'post-1');

      final container = ProviderContainer(
        overrides: [watchPostUseCaseProvider.overrideWithValue(watchPost)],
      );
      addTearDown(container.dispose);

      container.read(postDetailProvider('post-1', seed: seed));

      // Emit data first so the Completer inside build() is completed.
      // This prevents completer.completeError from firing on a subsequent error.
      repo.postController.add(updatedPost);
      await Future<void>.value();
      await Future<void>.value();

      final state = container.read(postDetailProvider('post-1', seed: seed));
      expect(state, isA<AsyncData<Post>>());
      expect((state as AsyncData<Post>).value, same(updatedPost));

      await repo.postController.close();
    });

    test('stream error after data emitted does not overwrite existing '
        'AsyncData value', () async {
      // Strategy: emit data first (completing the internal Completer), then
      // emit an error. This avoids an unhandled Future error from the
      // Completer while still testing the "hasValue → skip error" branch.
      final repo = FakePostRepository();
      final watchPost = _FakeWatchPost(repo);

      final seed = fakePost(id: 'post-1');

      final container = ProviderContainer(
        overrides: [watchPostUseCaseProvider.overrideWithValue(watchPost)],
      );
      addTearDown(container.dispose);

      container.listen(postDetailProvider('post-1', seed: seed), (prev, next) {});

      // First: emit a data event to complete the internal Completer.
      final dataPost = fakePost(id: 'post-1');
      repo.postController.add(dataPost);
      await Future<void>.value();
      await Future<void>.value();

      // Verify we have a value.
      final beforeError = container.read(
        postDetailProvider('post-1', seed: seed),
      );
      expect(beforeError.hasValue, isTrue);

      // Now emit the error — since Completer is already completed, the
      // onError handler only checks `if (!state.hasValue)` and skips.
      repo.postController.addError(
        Exception('network error'),
        StackTrace.current,
      );
      await Future<void>.value();
      await Future<void>.value();

      final afterError = container.read(
        postDetailProvider('post-1', seed: seed),
      );
      // State still has a value — error did not overwrite it.
      expect(afterError.hasValue, isTrue);
      expect(afterError.value, isNotNull);

      await repo.postController.close();
    });
  });

  group('postDetailProvider — cold-start (no seed)', () {
    test('state is AsyncLoading before first stream event', () async {
      final repo = FakePostRepository();
      final watchPost = _FakeWatchPost(repo);

      final container = ProviderContainer(
        overrides: [watchPostUseCaseProvider.overrideWithValue(watchPost)],
      );
      addTearDown(container.dispose);

      final state = container.read(postDetailProvider('post-1'));
      expect(state, isA<AsyncLoading<Post>>());

      await repo.postController.close();
    });

    test('state becomes AsyncData after first stream event', () async {
      final repo = FakePostRepository();
      final watchPost = _FakeWatchPost(repo);

      final container = ProviderContainer(
        overrides: [watchPostUseCaseProvider.overrideWithValue(watchPost)],
      );
      addTearDown(container.dispose);

      container.listen(postDetailProvider('post-1'), (prev, next) {});

      final post = fakePost();
      repo.postController.add(post);

      final value = await container.read(postDetailProvider('post-1').future);
      expect(value, same(post));

      final state = container.read(postDetailProvider('post-1'));
      expect(state, isA<AsyncData<Post>>());

      await repo.postController.close();
    });

    test('cold-start stream error: provider reflects error in state', () async {
      // The build() returns completer.future. When addError fires, the
      // onError handler calls completer.completeError(e, st), which causes
      // build() to throw. Riverpod v3 catches that and stores the error.
      // The state may be AsyncError or AsyncLoading with .error set (retry).
      // Either way, we verify the error is captured.
      final repo = FakePostRepository();
      final watchPost = _FakeWatchPost(repo);

      final container = ProviderContainer(
        overrides: [watchPostUseCaseProvider.overrideWithValue(watchPost)],
      );
      addTearDown(container.dispose);

      // Listen (absorb state change errors from Riverpod retry mechanism).
      container.listen(
        postDetailProvider('post-1'),
        (prev, next) {},
        onError: (err, st) {},
      );

      // The .future getter will throw when the build future throws.
      final futureResult = container
          .read(postDetailProvider('post-1').future)
          .then<Object?>((v) => v)
          .onError<Object>((e, st) => e); // capture error as value

      // Trigger the error on the stream.
      repo.postController.addError(
        Exception('load failed'),
        StackTrace.current,
      );

      final result = await futureResult;

      // The future should have resolved with the captured exception.
      expect(result, isA<Exception>());

      await repo.postController.close();
    });
  });
}
