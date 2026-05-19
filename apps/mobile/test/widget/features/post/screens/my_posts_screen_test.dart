import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';
import 'package:unishare_mobile/features/post/domain/usecases/watch_my_posts.dart';
import 'package:unishare_mobile/features/post/presentation/providers/my_posts_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';
import 'package:unishare_mobile/features/post/presentation/screens/my_posts_screen.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post_snapshot.dart';
import 'package:unishare_mobile/features/saved/domain/repositories/saved_post_repository.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/saved_post_repository_provider.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakePostRepository implements PostRepository {
  final StreamController<List<Post>> _myPostsController =
      StreamController<List<Post>>.broadcast();

  void emitPosts(List<Post> posts) => _myPostsController.add(posts);

  @override
  Stream<List<Post>> watchPostsByAuthor(String authorId, {int limit = 50}) =>
      _myPostsController.stream;

  @override
  Future<int> countPostsByAuthor(String authorId) async => 0;

  @override
  Future<void> incrementViewCount(String postId) async {}

  @override
  Stream<List<Post>> watchFeed({int limit = 20}) => throw UnimplementedError();

  @override
  Stream<Post> watchPost(String postId) => throw UnimplementedError();

  @override
  Future<void> saveDraft(PostDraft draft) => throw UnimplementedError();

  @override
  Future<void> removeDraft(String draftId) => throw UnimplementedError();

  @override
  Future<List<PostDraft>> loadDraftQueue() => throw UnimplementedError();

  @override
  Future<void> publishDraft(
    PostDraft draft, {
    void Function(double)? onProgress,
    void Function(int, double)? onFileProgress,
    void Function(PostDraft)? onDraftUpdated,
    Map<String, Uint8List>? fileDataOverride,
    CancellationToken? cancellationToken,
  }) => throw UnimplementedError();
}

class _FakeSavedPostRepository implements SavedPostRepository {
  @override
  Stream<List<SavedPost>> watchSavedPosts() => const Stream.empty();

  @override
  Future<void> savePost(String postId, SavedPostSnapshot snapshot) async {}

  @override
  Future<void> unsavePost(String postId) async {}

  @override
  Stream<bool> isPostSaved(String postId) => Stream.value(false);

  @override
  Future<void> mergeFrom(List<SavedPost> guestSaves) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _scrollKey = GlobalKey<State>();

Post _fakePost({String id = 'post-1', String title = 'Test Post'}) => Post(
  id: id,
  authorId: 'uid-1',
  authorName: 'Tester',
  authorAvatar: '',
  postType: PostType.lectureNote,
  year: 2,
  courseId: 'CSC101',
  title: title,
  description: 'Some description',
  postingIdentity: PostingIdentity.named,
  semester: 1,
  moduleNumber: '',
  mediaUrls: const [],
  tags: const ['flutter'],
  likesCount: 3,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Widget _buildSubject({required _FakePostRepository postRepo}) {
  return ProviderScope(
    overrides: [
      watchMyPostsUseCaseProvider.overrideWithValue(WatchMyPosts(postRepo)),
      myPostsProvider.overrideWith(
        (ref) => postRepo.watchPostsByAuthor('uid-1'),
      ),
      savedPostRepositoryProvider.overrideWithValue(_FakeSavedPostRepository()),
    ],
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: MyPostsScreen(scrollKey: _scrollKey),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MyPostsScreen', () {
    testWidgets('shows loading indicator while waiting for first event', (
      tester,
    ) async {
      final postRepo = _FakePostRepository();
      await tester.pumpWidget(_buildSubject(postRepo: postRepo));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no posts', (tester) async {
      final postRepo = _FakePostRepository();
      await tester.pumpWidget(_buildSubject(postRepo: postRepo));

      postRepo.emitPosts([]);
      await tester.pump();

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text("You haven't posted anything yet."), findsOneWidget);
      expect(find.text('Share your first resource'), findsOneWidget);
    });

    testWidgets('shows list of posts when data is available', (tester) async {
      final postRepo = _FakePostRepository();
      await tester.pumpWidget(_buildSubject(postRepo: postRepo));

      postRepo.emitPosts([
        _fakePost(id: 'p1', title: 'First Post'),
        _fakePost(id: 'p2', title: 'Second Post'),
      ]);
      await tester.pump();

      expect(find.text('First Post'), findsOneWidget);
      expect(find.text('Second Post'), findsOneWidget);
    });

    testWidgets('appbar shows "My Posts" title', (tester) async {
      final postRepo = _FakePostRepository();
      await tester.pumpWidget(_buildSubject(postRepo: postRepo));

      postRepo.emitPosts([]);
      await tester.pump();

      expect(find.text('My Posts'), findsOneWidget);
    });

    testWidgets('appbar has New Post action button', (tester) async {
      final postRepo = _FakePostRepository();
      await tester.pumpWidget(_buildSubject(postRepo: postRepo));

      postRepo.emitPosts([]);
      await tester.pump();

      expect(find.text('New Post'), findsOneWidget);
    });

    testWidgets('uses ListView.builder for non-empty list', (tester) async {
      final postRepo = _FakePostRepository();
      await tester.pumpWidget(_buildSubject(postRepo: postRepo));

      postRepo.emitPosts([
        _fakePost(id: 'p1', title: 'Alpha'),
        _fakePost(id: 'p2', title: 'Beta'),
        _fakePost(id: 'p3', title: 'Gamma'),
      ]);
      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
    });
  });
}
