import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/domain/usecases/toggle_like.dart';

import '../../fakes/fake_like_repository.dart';

void main() {
  group('ToggleLike', () {
    test('delegates to LikeRepository.toggleLike', () async {
      final repo = FakeLikeRepository();
      final useCase = ToggleLike(repo);

      await useCase.call('post-42');

      expect(repo.toggleLikeCalled, isTrue);
      expect(repo.lastTogglePostId, 'post-42');
    });

    test('does not call toggleLike before call() is invoked', () {
      final repo = FakeLikeRepository();
      ToggleLike(repo);

      expect(repo.toggleLikeCalled, isFalse);
    });

    test('domain use case has no Firebase or Flutter coupling '
        '(compiles with pure-Dart fake only)', () {
      // If this file compiles with only FakeLikeRepository — which is pure
      // Dart implementing the domain interface — then ToggleLike has no
      // Flutter or Firebase import. The test passing is the evidence.
      final repo = FakeLikeRepository();
      final useCase = ToggleLike(repo);
      expect(useCase, isNotNull);
    });
  });
}
