import '../entities/post.dart';
import '../entities/post_feed_page.dart';

abstract class PostRepository {
  Future<PostFeedPage> getPostFeed({int page = 0, int pageSize = 20});
  Future<Post> getPost(String postId);
  Future<void> toggleLike(String postId, {required bool liked});
  Future<void> deletePost(String postId);
}
