import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unishare_mobile/features/post_feed/domain/entities/post.dart';
import 'package:unishare_mobile/features/post_feed/domain/entities/post_feed_page.dart';
import 'package:unishare_mobile/features/post_feed/domain/repositories/post_repository.dart';
import 'package:unishare_mobile/features/post_feed/presentation/providers/post_feed_provider.dart';

class MockPostRepository extends Mock implements PostRepository {}

Post _fakePost({
  String id = 'p1',
  bool isLiked = false,
  int likes = 0,
}) =>
    Post(
      id: id,
      authorId: 'u1',
      authorName: 'Alice',
      authorAvatar: '',
      title: 'Title',
      body: 'Body',
      mediaUrls: const [],
      tags: const [],
      likesCount: likes,
      isLikedByCurrentUser: isLiked,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

ProviderContainer _buildContainer(PostRepository repo) {
  return ProviderContainer(
    overrides: [
      postRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

void main() {
  late MockPostRepository repo;

  setUp(() {
    repo = MockPostRepository();
    registerFallbackValue(_fakePost());
  });

  group('build (initial load)', () {
    test('loads first page and exposes posts', () async {
      final posts = List.generate(5, (i) => _fakePost(id: 'p$i'));
      when(() => repo.getPostFeed(page: 0, pageSize: 20))
          .thenAnswer((_) async => PostFeedPage(posts: posts, page: 0, hasMore: false));

      final container = _buildContainer(repo);
      addTearDown(container.dispose);

      final state = await container.read(postFeedProvider.future);

      expect(state.posts.length, 5);
      expect(state.hasMore, isFalse);
    });
  });

  group('fetchNextPage', () {
    test('appends posts from next page', () async {
      final page0 = List.generate(20, (i) => _fakePost(id: 'p$i'));
      final page1 = [_fakePost(id: 'p20')];

      when(() => repo.getPostFeed(page: 0, pageSize: 20))
          .thenAnswer((_) async => PostFeedPage(posts: page0, page: 0, hasMore: true));
      when(() => repo.getPostFeed(page: 1, pageSize: 20))
          .thenAnswer((_) async => PostFeedPage(posts: page1, page: 1, hasMore: false));

      final container = _buildContainer(repo);
      addTearDown(container.dispose);

      await container.read(postFeedProvider.future);
      await container.read(postFeedProvider.notifier).fetchNextPage();

      final state = container.read(postFeedProvider).asData!.value;
      expect(state.posts.length, 21);
      expect(state.hasMore, isFalse);
    });

    test('guard prevents duplicate concurrent fetches', () async {
      final page0 = List.generate(20, (i) => _fakePost(id: 'p$i'));
      final page1 = [_fakePost(id: 'p20')];

      when(() => repo.getPostFeed(page: 0, pageSize: 20))
          .thenAnswer((_) async => PostFeedPage(posts: page0, page: 0, hasMore: true));
      when(() => repo.getPostFeed(page: 1, pageSize: 20))
          .thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return PostFeedPage(posts: page1, page: 1, hasMore: false);
      });

      final container = _buildContainer(repo);
      addTearDown(container.dispose);

      await container.read(postFeedProvider.future);

      // Fire two concurrent fetches — only one should reach the repo.
      await Future.wait<void>([
        container.read(postFeedProvider.notifier).fetchNextPage(),
        container.read(postFeedProvider.notifier).fetchNextPage(),
      ]);

      verify(() => repo.getPostFeed(page: 1, pageSize: 20)).called(1);
    });
  });

  group('toggleLike', () {
    test('applies optimistic update immediately', () async {
      final post = _fakePost(id: 'p1', isLiked: false, likes: 2);
      when(() => repo.getPostFeed(page: 0, pageSize: 20)).thenAnswer(
        (_) async => PostFeedPage(posts: [post], page: 0, hasMore: false),
      );
      when(() => repo.toggleLike('p1', liked: true))
          .thenAnswer((_) async => Future<void>.delayed(const Duration(seconds: 1)));

      final container = _buildContainer(repo);
      addTearDown(container.dispose);
      await container.read(postFeedProvider.future);

      // Don't await — check state after the optimistic mutation but before
      // the async call completes.
      unawaited(
        container.read(postFeedProvider.notifier).toggleLike('p1', liked: true),
      );

      final state = container.read(postFeedProvider).asData!.value;
      expect(state.posts.first.isLikedByCurrentUser, isTrue);
      expect(state.posts.first.likesCount, 3);
    });

    test('reverts on error', () async {
      final post = _fakePost(id: 'p1', isLiked: false, likes: 2);
      when(() => repo.getPostFeed(page: 0, pageSize: 20)).thenAnswer(
        (_) async => PostFeedPage(posts: [post], page: 0, hasMore: false),
      );
      when(() => repo.toggleLike('p1', liked: true)).thenThrow(Exception('err'));

      final container = _buildContainer(repo);
      addTearDown(container.dispose);
      await container.read(postFeedProvider.future);

      await expectLater(
        () => container
            .read(postFeedProvider.notifier)
            .toggleLike('p1', liked: true),
        throwsException,
      );

      final state = container.read(postFeedProvider).asData!.value;
      expect(state.posts.first.isLikedByCurrentUser, isFalse);
      expect(state.posts.first.likesCount, 2);
    });
  });
}

void unawaited(Future<void> future) {}
