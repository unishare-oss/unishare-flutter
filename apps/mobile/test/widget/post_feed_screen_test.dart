import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unishare_mobile/features/post_feed/domain/entities/post.dart';
import 'package:unishare_mobile/features/post_feed/domain/entities/post_feed_page.dart';
import 'package:unishare_mobile/features/post_feed/domain/repositories/post_repository.dart';
import 'package:unishare_mobile/features/post_feed/presentation/providers/post_feed_provider.dart';
import 'package:unishare_mobile/features/post_feed/presentation/screens/post_feed_screen.dart';

class MockPostRepository extends Mock implements PostRepository {}

Post _fakePost(String id) => Post(
      id: id,
      authorId: 'u1',
      authorName: 'Alice',
      authorAvatar: '',
      title: 'Post $id',
      body: 'Body of post $id',
      mediaUrls: const [],
      tags: const ['dart', 'flutter'],
      likesCount: 0,
      isLikedByCurrentUser: false,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

Widget _buildSubject(PostRepository repo) {
  return ProviderScope(
    overrides: [postRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(home: PostFeedScreen()),
  );
}

void main() {
  late MockPostRepository repo;

  setUp(() => repo = MockPostRepository());

  testWidgets('shows loading indicator while feed is loading', (tester) async {
    // Never completes — keeps the provider in loading state.
    when(() => repo.getPostFeed(page: 0, pageSize: 20))
        .thenAnswer((_) async => Future.delayed(const Duration(hours: 1), () {
              return const PostFeedPage(posts: [], page: 0, hasMore: false);
            }));

    await tester.pumpWidget(_buildSubject(repo));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders post cards when data loads', (tester) async {
    final posts = [_fakePost('p1'), _fakePost('p2')];
    when(() => repo.getPostFeed(page: 0, pageSize: 20))
        .thenAnswer((_) async => PostFeedPage(posts: posts, page: 0, hasMore: false));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pump(); // start async build
    await tester.pump(const Duration(milliseconds: 100)); // settle

    expect(find.text('Post p1'), findsOneWidget);
    expect(find.text('Post p2'), findsOneWidget);
  });

  testWidgets('shows end-of-feed indicator when hasMore is false', (tester) async {
    when(() => repo.getPostFeed(page: 0, pageSize: 20))
        .thenAnswer((_) async => PostFeedPage(posts: [_fakePost('p1')], page: 0, hasMore: false));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text("You're all caught up"), findsOneWidget);
  });

  testWidgets('shows retry button on load error', (tester) async {
    when(() => repo.getPostFeed(page: 0, pageSize: 20))
        .thenThrow(Exception('Network error'));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Failed to load feed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('pull-to-refresh triggers feed reload', (tester) async {
    when(() => repo.getPostFeed(page: 0, pageSize: 20))
        .thenAnswer((_) async => PostFeedPage(posts: [_fakePost('p1')], page: 0, hasMore: false));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Trigger pull-to-refresh.
    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // getPostFeed should have been called at least twice (initial + refresh).
    verify(() => repo.getPostFeed(page: 0, pageSize: 20)).called(greaterThanOrEqualTo(2));
  });
}
