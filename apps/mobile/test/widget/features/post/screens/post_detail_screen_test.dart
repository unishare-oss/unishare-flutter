import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/post/domain/entities/comment.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/domain/repositories/comment_repository.dart';
import 'package:unishare_mobile/features/post/domain/repositories/like_repository.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';
import 'package:unishare_mobile/features/post/domain/usecases/add_comment.dart';
import 'package:unishare_mobile/features/post/domain/usecases/toggle_like.dart';
import 'package:unishare_mobile/features/post/domain/usecases/watch_comments.dart';
import 'package:unishare_mobile/features/post/domain/usecases/watch_post.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';
import 'package:unishare_mobile/features/post/presentation/screens/post_detail_screen.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakePostRepository implements PostRepository {
  final StreamController<Post> controller = StreamController<Post>.broadcast();

  @override
  Stream<Post> watchPost(String postId) => controller.stream;

  @override
  Stream<List<Post>> watchFeed({int limit = 20}) => throw UnimplementedError();

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
    Map<String, Uint8List>? fileDataOverride,
  }) => throw UnimplementedError();
}

class _FakeCommentRepository implements CommentRepository {
  final StreamController<List<Comment>> controller =
      StreamController<List<Comment>>.broadcast();

  @override
  Stream<List<Comment>> watchComments(String postId) => controller.stream;

  @override
  Future<void> addComment(String postId, String body) async {}
}

class _FakeLikeRepository implements LikeRepository {
  final StreamController<bool> controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> watchLikeStatus(String postId) => controller.stream;

  @override
  Future<void> toggleLike(String postId) async {}
}

// ---------------------------------------------------------------------------
// Factory helpers
// ---------------------------------------------------------------------------

Post _fakePost() => Post(
  id: 'post-1',
  authorId: 'author-1',
  authorName: 'Test Author',
  authorAvatar: '',
  postType: PostType.lectureNote,
  year: 1,
  courseId: 'csc101',
  title: 'Test Title',
  description: 'Test body content',
  postingIdentity: PostingIdentity.named,
  semester: 1,
  moduleNumber: '',
  mediaUrls: const [],
  tags: const ['flutter'],
  likesCount: 5,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

/// Builds the widget under test.
///
/// [seed] — a [Post] to bypass the cold-start loading state (warm-start).
/// Pass [null] to test loading state.
///
/// [disableRetry] — sets `retry: (_,__) => null` on the [ProviderScope] so
/// that errors cause an immediate [AsyncError] rather than an
/// [AsyncLoading(retrying: true)] state (Riverpod v3 default retry).
Widget _buildSubject({
  Post? seed,
  bool disableRetry = false,
  _FakePostRepository? postRepo,
  _FakeCommentRepository? commentRepo,
  _FakeLikeRepository? likeRepo,
}) {
  final p = postRepo ?? _FakePostRepository();
  final c = commentRepo ?? _FakeCommentRepository();
  final l = likeRepo ?? _FakeLikeRepository();

  return ProviderScope(
    retry: disableRetry ? (retryCount, error) => null : null,
    overrides: [
      guestModeProvider.overrideWithValue(false),
      watchPostUseCaseProvider.overrideWithValue(WatchPost(p)),
      watchCommentsUseCaseProvider.overrideWithValue(WatchComments(c)),
      likeRepositoryProvider.overrideWithValue(l),
      addCommentUseCaseProvider.overrideWithValue(AddComment(c)),
      toggleLikeUseCaseProvider.overrideWithValue(ToggleLike(l)),
    ],
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: PostDetailScreen(postId: 'post-1', seed: seed),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PostDetailScreen', () {
    testWidgets('loading state shows CircularProgressIndicator', (
      tester,
    ) async {
      // No seed → cold-start → AsyncLoading.
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('loaded state renders title, body, author, and tag', (
      tester,
    ) async {
      // Warm-start with seed → AsyncData immediately.
      await tester.pumpWidget(_buildSubject(seed: _fakePost()));
      await tester.pump();

      expect(find.text('Test Title'), findsAtLeastNWidgets(1));
      expect(find.text('Test body content'), findsOneWidget);
      expect(find.text('Test Author'), findsOneWidget);
      // Tag is rendered in upper case by the screen.
      expect(find.text('FLUTTER'), findsOneWidget);
    });

    testWidgets('error state shows error widget with error_outline icon', (
      tester,
    ) async {
      // Use disableRetry so the error transitions to AsyncError immediately
      // instead of AsyncLoading(retrying: true) from Riverpod v3 default retry.
      final postRepo = _FakePostRepository();
      final commentRepo = _FakeCommentRepository();
      final likeRepo = _FakeLikeRepository();

      await tester.pumpWidget(
        _buildSubject(
          disableRetry: true,
          postRepo: postRepo,
          commentRepo: commentRepo,
          likeRepo: likeRepo,
        ),
      );
      await tester.pump(); // cold-start loading

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Emit an error on the post stream (cold-start: no data was ever sent).
      postRepo.controller.addError(
        Exception('load failed'),
        StackTrace.current,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('no BottomNavigationBar present in the widget tree', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(seed: _fakePost()));
      await tester.pump();

      expect(find.byType(BottomNavigationBar), findsNothing);
    });
  });
}
