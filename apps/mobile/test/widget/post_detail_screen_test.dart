import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unishare_mobile/features/post_feed/domain/entities/post.dart';
import 'package:unishare_mobile/features/post_feed/domain/entities/post_feed_page.dart';
import 'package:unishare_mobile/features/post_feed/domain/repositories/post_repository.dart';
import 'package:unishare_mobile/features/post_feed/presentation/providers/post_feed_provider.dart';
import 'package:unishare_mobile/features/post_feed/presentation/screens/post_detail_screen.dart';

class MockPostRepository extends Mock implements PostRepository {}

Post _fakePost({String authorId = 'u1'}) => Post(
      id: 'p1',
      authorId: authorId,
      authorName: 'Alice',
      authorAvatar: '',
      title: 'Detailed Post Title',
      body: 'Full body content for this post.',
      mediaUrls: const [],
      tags: const [],
      likesCount: 5,
      isLikedByCurrentUser: false,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

Widget _buildSubject(PostRepository repo, {String postId = 'p1'}) {
  return ProviderScope(
    overrides: [postRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(home: PostDetailScreen(postId: postId)),
  );
}

void main() {
  late MockPostRepository repo;

  setUp(() {
    repo = MockPostRepository();
    // postFeedNotifier is used by the like button in the detail screen;
    // we need to stub the feed load so it doesn't fail.
    when(() => repo.getPostFeed(page: 0, pageSize: 20))
        .thenAnswer((_) async => const PostFeedPage(posts: [], page: 0, hasMore: false));
  });

  testWidgets('renders post title and body', (tester) async {
    when(() => repo.getPost('p1')).thenAnswer((_) async => _fakePost());

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Detailed Post Title'), findsOneWidget);
    expect(find.text('Full body content for this post.'), findsOneWidget);
  });

  testWidgets('renders author name', (tester) async {
    when(() => repo.getPost('p1')).thenAnswer((_) async => _fakePost());

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Alice'), findsOneWidget);
  });

  testWidgets('like button is visible', (tester) async {
    when(() => repo.getPost('p1')).thenAnswer((_) async => _fakePost());

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('shows error state for missing post', (tester) async {
    when(() => repo.getPost('p1')).thenThrow(Exception('Post not found'));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Post not found'), findsOneWidget);
    expect(find.text('Go back'), findsOneWidget);
  });
}
