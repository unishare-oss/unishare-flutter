import 'post.dart';

class PostFeedPage {
  const PostFeedPage({
    required this.posts,
    required this.page,
    required this.hasMore,
  });

  final List<Post> posts;
  final int page;
  final bool hasMore;
}
