import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/user_like_status_provider.dart';

import '../../fakes/fake_like_repository.dart';

void main() {
  group('userLikeStatusProvider', () {
    test('emits true when liked', () async {
      final repo = FakeLikeRepository();

      final container = ProviderContainer(
        overrides: [likeRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      container.listen(userLikeStatusProvider('post-1'), (prev, next) {});

      repo.controller.add(true);
      await Future<void>.value();

      final state = container.read(userLikeStatusProvider('post-1'));
      expect(state, isA<AsyncData<bool>>());
      expect((state as AsyncData<bool>).value, isTrue);

      await repo.controller.close();
    });

    test('emits false when not liked', () async {
      final repo = FakeLikeRepository();

      final container = ProviderContainer(
        overrides: [likeRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      container.listen(userLikeStatusProvider('post-1'), (prev, next) {});

      repo.controller.add(false);
      await Future<void>.value();

      final state = container.read(userLikeStatusProvider('post-1'));
      expect(state, isA<AsyncData<bool>>());
      expect((state as AsyncData<bool>).value, isFalse);

      await repo.controller.close();
    });

    test(
      'emits false for guest user (stream emits false when no uid)',
      () async {
        // The repository's watchLikeStatus emits false when there is no
        // authenticated user. Simulate that by emitting false on the stream.
        final repo = FakeLikeRepository();

        final container = ProviderContainer(
          overrides: [likeRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        container.listen(userLikeStatusProvider('post-1'), (prev, next) {});

        repo.controller.add(false);
        await Future<void>.value();

        final state = container.read(userLikeStatusProvider('post-1'));
        expect((state as AsyncData<bool>).value, isFalse);

        await repo.controller.close();
      },
    );
  });
}
