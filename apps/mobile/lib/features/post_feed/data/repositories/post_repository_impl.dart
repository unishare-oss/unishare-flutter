import '../../domain/entities/post.dart';
import '../../domain/entities/post_feed_page.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_firestore_datasource.dart';

class PostRepositoryImpl implements PostRepository {
  const PostRepositoryImpl(this._dataSource);

  final PostFirestoreDataSource _dataSource;

  @override
  Future<PostFeedPage> getPostFeed({int page = 0, int pageSize = 20}) async {
    final models = await _dataSource.getPostFeed(page: page, pageSize: pageSize);
    return PostFeedPage(
      posts: models.map((m) => m.toEntity()).toList(),
      page: page,
      hasMore: models.length == pageSize,
    );
  }

  @override
  Future<Post> getPost(String postId) async {
    final model = await _dataSource.getPost(postId);
    return model.toEntity();
  }

  @override
  Future<void> toggleLike(String postId, {required bool liked}) {
    return _dataSource.toggleLike(postId, liked: liked);
  }

  @override
  Future<void> deletePost(String postId) {
    return _dataSource.deletePost(postId);
  }
}
