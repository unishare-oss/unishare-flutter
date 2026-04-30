import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/post_firestore_datasource.dart';
import '../../data/mock/mock_posts.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/usecases/delete_post.dart';
import '../../domain/usecases/get_post_feed.dart';
import '../../domain/usecases/toggle_like.dart';

part 'post_feed_provider.g.dart';

// Flip to false to use Firestore.
const _kMockFeed = true;

class PostFeedState {
  const PostFeedState({
    required this.posts,
    required this.hasMore,
    this.isFetchingMore = false,
  });

  final List<Post> posts;
  final bool hasMore;
  final bool isFetchingMore;

  PostFeedState copyWith({
    List<Post>? posts,
    bool? hasMore,
    bool? isFetchingMore,
  }) {
    return PostFeedState(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }
}

@riverpod
PostFirestoreDataSource postFirestoreDataSource(Ref ref) {
  return PostFirestoreDataSource(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
}

@riverpod
PostRepository postRepository(Ref ref) {
  return PostRepositoryImpl(ref.read(postFirestoreDataSourceProvider));
}

@riverpod
class PostFeedNotifier extends _$PostFeedNotifier {
  int _nextPage = 0;

  @override
  Future<PostFeedState> build() async {
    if (_kMockFeed) {
      return PostFeedState(posts: kMockPosts, hasMore: false);
    }
    _nextPage = 0;
    final useCase = GetPostFeed(ref.read(postRepositoryProvider));
    final page = await useCase(page: 0);
    _nextPage = 1;
    return PostFeedState(posts: page.posts, hasMore: page.hasMore);
  }

  Future<void> fetchNextPage() async {
    if (_kMockFeed) return;
    final current = state.asData?.value;
    if (current == null || current.isFetchingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isFetchingMore: true));

    try {
      final useCase = GetPostFeed(ref.read(postRepositoryProvider));
      final page = await useCase(page: _nextPage);
      _nextPage++;
      state = AsyncData(PostFeedState(
        posts: [...current.posts, ...page.posts],
        hasMore: page.hasMore,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(isFetchingMore: false));
      rethrow;
    }
  }

  Future<void> toggleLike(String postId, {required bool liked}) async {
    final current = state.asData?.value;
    if (current == null) return;

    final idx = current.posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final original = current.posts[idx];
    final updated = original.copyWith(
      isLikedByCurrentUser: liked,
      likesCount: original.likesCount + (liked ? 1 : -1),
    );

    final newPosts = [...current.posts];
    newPosts[idx] = updated;
    state = AsyncData(current.copyWith(posts: newPosts));

    if (_kMockFeed) return;

    try {
      final useCase = ToggleLike(ref.read(postRepositoryProvider));
      await useCase(postId, liked: liked);
    } catch (e) {
      newPosts[idx] = original;
      state = AsyncData(current.copyWith(posts: List.unmodifiable(newPosts)));
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    if (!_kMockFeed) {
      final useCase = DeletePost(ref.read(postRepositoryProvider));
      await useCase(postId);
    }

    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(posts: current.posts.where((p) => p.id != postId).toList()),
    );
  }
}

@riverpod
Future<Post> postDetail(Ref ref, String postId) {
  return ref.read(postRepositoryProvider).getPost(postId);
}

