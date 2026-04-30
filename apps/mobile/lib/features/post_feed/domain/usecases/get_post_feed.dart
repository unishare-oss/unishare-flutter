import '../entities/post_feed_page.dart';
import '../repositories/post_repository.dart';

class GetPostFeed {
  const GetPostFeed(this._repository);

  final PostRepository _repository;

  Future<PostFeedPage> call({int page = 0, int pageSize = 20}) {
    return _repository.getPostFeed(page: page, pageSize: pageSize);
  }
}
