import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/domain/usecases/add_comment.dart';

import '../../fakes/fake_comment_repository.dart';

void main() {
  group('AddComment', () {
    test('blank body throws ArgumentError', () {
      final repo = FakeCommentRepository();
      final useCase = AddComment(repo);

      expect(
        () => useCase.call('post-1', ''),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Comment body must not be blank',
          ),
        ),
      );
    });

    test('whitespace-only body throws ArgumentError', () {
      final repo = FakeCommentRepository();
      final useCase = AddComment(repo);

      expect(
        () => useCase.call('post-1', '   '),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Comment body must not be blank',
          ),
        ),
      );
    });

    test('tab-only body throws ArgumentError', () {
      final repo = FakeCommentRepository();
      final useCase = AddComment(repo);

      expect(
        () => useCase.call('post-1', '\t\n'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('valid body delegates trimmed value to repository', () async {
      final repo = FakeCommentRepository();
      final useCase = AddComment(repo);

      await useCase.call('post-1', '  Hello world  ');

      expect(repo.lastAddedPostId, 'post-1');
      expect(repo.lastAddedBody, 'Hello world');
    });

    test('valid body without surrounding whitespace delegates as-is', () async {
      final repo = FakeCommentRepository();
      final useCase = AddComment(repo);

      await useCase.call('post-1', 'Great post!');

      expect(repo.lastAddedBody, 'Great post!');
    });

    test('passes parentId to repository when provided', () async {
      final repo = FakeCommentRepository();
      final useCase = AddComment(repo);

      await useCase.call('post-1', 'A reply', parentId: 'comment-99');

      expect(repo.lastAddedParentId, 'comment-99');
    });

    test('passes null parentId when not provided', () async {
      final repo = FakeCommentRepository();
      final useCase = AddComment(repo);

      await useCase.call('post-1', 'Top-level comment');

      expect(repo.lastAddedParentId, isNull);
    });
  });
}
