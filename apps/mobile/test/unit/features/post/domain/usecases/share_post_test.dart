import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/domain/repositories/share_repository.dart';
import 'package:unishare_mobile/features/post/domain/usecases/share_post.dart';

// ---------------------------------------------------------------------------
// Fake ShareRepository
// ---------------------------------------------------------------------------

class _FakeShareRepository implements ShareRepository {
  Post? lastPost;
  bool shouldThrow = false;
  Object? errorToThrow;

  @override
  Future<void> share(Post post) async {
    lastPost = post;
    if (shouldThrow) throw errorToThrow!;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Post _makePost({String id = 'post-1', String title = 'Test Post'}) => Post(
  id: id,
  authorId: 'author-1',
  authorName: 'Author',
  authorAvatar: '',
  postType: PostType.lectureNote,
  year: 1,
  courseId: 'csc101',
  title: title,
  description: 'body',
  postingIdentity: PostingIdentity.named,
  semester: 1,
  moduleNumber: '',
  mediaUrls: const [],
  tags: const [],
  likesCount: 0,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SharePostUseCase', () {
    test('calls ShareRepository.share with the correct Post', () async {
      final repo = _FakeShareRepository();
      final useCase = SharePostUseCase(repo);
      final post = _makePost();

      await useCase.call(post);

      expect(repo.lastPost, same(post));
    });

    test('completes normally when repository succeeds', () async {
      final repo = _FakeShareRepository();
      final useCase = SharePostUseCase(repo);

      await expectLater(useCase.call(_makePost()), completes);
    });

    test('propagates exception thrown by repository', () async {
      final repo = _FakeShareRepository()
        ..shouldThrow = true
        ..errorToThrow = Exception('share failed');
      final useCase = SharePostUseCase(repo);

      await expectLater(useCase.call(_makePost()), throwsA(isA<Exception>()));
    });
  });
}
