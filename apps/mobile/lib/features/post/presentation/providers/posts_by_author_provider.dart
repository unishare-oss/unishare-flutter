import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';

part 'posts_by_author_provider.g.dart';

/// Streams a given author's posts ordered newest-first. Used by the
/// public profile screen — distinct from [myPosts] which is anchored to
/// the signed-in user. Anonymous-mode filtering is the caller's
/// responsibility (the public profile view excludes them; private
/// surfaces like /posts may include them).
@riverpod
Stream<List<Post>> postsByAuthor(Ref ref, String authorId) {
  return ref.watch(watchMyPostsUseCaseProvider).call(authorId);
}
