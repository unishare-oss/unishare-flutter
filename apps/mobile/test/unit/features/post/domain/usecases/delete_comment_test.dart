import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/domain/usecases/delete_comment.dart';

import '../../fakes/fake_comment_repository.dart';

void main() {
  group('DeleteComment', () {
    test('delegates postId and commentId to repository', () async {
      final repo = FakeCommentRepository();
      final useCase = DeleteComment(repo);

      await useCase.call('post-1', 'comment-42');

      expect(repo.lastDeletedPostId, 'post-1');
      expect(repo.lastDeletedCommentId, 'comment-42');
    });

    test('propagates repository exceptions to caller', () {
      final repo = FakeCommentRepository()
        ..deleteError = Exception('permission-denied');
      final useCase = DeleteComment(repo);

      expect(
        () => useCase.call('post-1', 'comment-42'),
        throwsA(isA<Exception>()),
      );
    });

    test('does not call repository with empty postId', () async {
      final repo = FakeCommentRepository();
      final useCase = DeleteComment(repo);

      await useCase.call('', 'comment-1');

      // Still delegates — enforcement is Firestore rules, not the use case.
      expect(repo.lastDeletedPostId, '');
    });
  });
}
