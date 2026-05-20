import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/domain/usecases/watch_post.dart';

import '../../fakes/fake_post_repository.dart';
import '../../fakes/post_factories.dart';

void main() {
  group('WatchPost', () {
    test('call forwards the repository stream unchanged', () async {
      final repo = FakePostRepository();
      final useCase = WatchPost(repo);

      final post = fakePost();

      // Collect all emitted values using async expansion.
      final emitted = <dynamic>[];
      final sub = useCase.call('post-1').listen(emitted.add);

      repo.postController.add(post);
      await Future<void>.value();

      expect(emitted, hasLength(1));
      expect(emitted.first, same(post));

      await sub.cancel();
      await repo.postController.close();
    });

    test('streams multiple events in order', () async {
      final repo = FakePostRepository();
      final useCase = WatchPost(repo);

      final post1 = fakePost(id: 'p-1');
      final post2 = fakePost(id: 'p-2');

      final emitted = <dynamic>[];
      final sub = useCase.call('post-1').listen(emitted.add);

      // Broadcast stream delivers events synchronously to existing listeners.
      // Add each event, then flush microtasks.
      repo.postController.add(post1);
      await Future<void>.value();
      repo.postController.add(post2);
      await Future<void>.value();

      expect(emitted, [post1, post2]);

      await sub.cancel();
      await repo.postController.close();
    });
  });
}
