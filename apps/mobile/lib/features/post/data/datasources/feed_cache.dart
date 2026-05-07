import 'package:unishare_mobile/features/post/domain/entities/post.dart';

class FeedCache {
  List<Post>? _posts;
  DateTime? _cachedAt;

  bool isValid(Duration ttl) =>
      _posts != null &&
      _cachedAt != null &&
      DateTime.now().difference(_cachedAt!) < ttl;

  List<Post> get posts {
    if (_posts == null) throw StateError('feed_cache_empty');
    return List.unmodifiable(_posts!);
  }

  void update(List<Post> posts) {
    _posts = posts;
    _cachedAt = DateTime.now();
  }

  void invalidate() {
    _posts = null;
    _cachedAt = null;
  }
}
