import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/data/datasources/share_plus_datasource.dart';
import 'package:unishare_mobile/features/post/data/repositories/share_repository_impl.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';

// ---------------------------------------------------------------------------
// Fake SharePlusDataSource — extends to override share()
// ---------------------------------------------------------------------------

class _FakeDataSource extends SharePlusDataSource {
  _FakeDataSource(this.resultToReturn);

  ShareFallbackResult resultToReturn;
  String? capturedPostId;
  String? capturedTitle;

  @override
  Future<ShareFallbackResult> share({
    required String postId,
    required String postTitle,
  }) async {
    capturedPostId = postId;
    capturedTitle = postTitle;
    return resultToReturn;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Post _makePost({String id = 'post-1', String title = 'My Post'}) => Post(
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
  group('ShareRepositoryImpl', () {
    test('returns normally when datasource returns shared', () async {
      final ds = _FakeDataSource(ShareFallbackResult.shared);
      final repo = ShareRepositoryImpl(ds);

      await expectLater(repo.share(_makePost()), completes);
    });

    test('passes post id and title to datasource', () async {
      final ds = _FakeDataSource(ShareFallbackResult.shared);
      final repo = ShareRepositoryImpl(ds);

      await repo.share(_makePost(id: 'abc-123', title: 'Great Notes'));

      expect(ds.capturedPostId, 'abc-123');
      expect(ds.capturedTitle, 'Great Notes');
    });

    test(
      'throws ShareFallbackException when datasource returns copiedToClipboard',
      () async {
        final ds = _FakeDataSource(ShareFallbackResult.copiedToClipboard);
        final repo = ShareRepositoryImpl(ds);

        await expectLater(
          repo.share(_makePost()),
          throwsA(isA<ShareFallbackException>()),
        );
      },
    );
  });
}
