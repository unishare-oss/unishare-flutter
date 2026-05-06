import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'post_repository_provider.dart';

part 'user_like_status_provider.g.dart';

@riverpod
Stream<bool> userLikeStatus(Ref ref, String postId) =>
    ref.watch(likeRepositoryProvider).watchLikeStatus(postId);
