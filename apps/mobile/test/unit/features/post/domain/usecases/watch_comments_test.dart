import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/domain/usecases/watch_comments.dart';

import '../../fakes/fake_comment_repository.dart';
import '../../fakes/post_factories.dart';

void main() {
  group('WatchComments', () {
    test('call forwards the repository stream unchanged', () async {
      final repo = FakeCommentRepository();
      final useCase = WatchComments(repo);

      final comments = [fakeComment()];

      final emitted = <dynamic>[];
      final sub = useCase.call('post-1').listen(emitted.add);

      repo.controller.add(comments);
      await Future<void>.value();

      expect(emitted, hasLength(1));
      expect(emitted.first, same(comments));

      await sub.cancel();
      await repo.controller.close();
    });

    test('streams multiple comment lists in order', () async {
      final repo = FakeCommentRepository();
      final useCase = WatchComments(repo);

      final list1 = [fakeComment(id: 'c-1')];
      final list2 = [fakeComment(id: 'c-1'), fakeComment(id: 'c-2')];

      final emitted = <dynamic>[];
      final sub = useCase.call('post-1').listen(emitted.add);

      // Add events one at a time, flushing microtasks between each.
      repo.controller.add(list1);
      await Future<void>.value();
      repo.controller.add(list2);
      await Future<void>.value();

      expect(emitted, [list1, list2]);

      await sub.cancel();
      await repo.controller.close();
    });
  });
}
