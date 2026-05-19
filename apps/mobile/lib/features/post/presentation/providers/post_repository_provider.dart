import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/core/storage/tag_whitelist_box.dart';
import 'package:unishare_mobile/features/post/data/datasources/comment_firestore_datasource.dart';
import 'package:unishare_mobile/features/post/data/datasources/feed_cache.dart';
import 'package:unishare_mobile/features/post/data/datasources/post_firestore_datasource.dart';
import 'package:unishare_mobile/features/post/data/datasources/post_storage_datasource.dart';
import 'package:unishare_mobile/features/post/data/datasources/share_plus_datasource.dart';
import 'package:unishare_mobile/features/post/data/datasources/tag_whitelist_service.dart';
import 'package:unishare_mobile/features/post/data/models/post_draft_model.dart';
import 'package:unishare_mobile/features/post/data/repositories/comment_repository_impl.dart';
import 'package:unishare_mobile/features/post/data/repositories/like_repository_impl.dart';
import 'package:unishare_mobile/features/post/data/repositories/post_repository_impl.dart';
import 'package:unishare_mobile/features/post/data/repositories/share_repository_impl.dart';
import 'package:unishare_mobile/features/post/domain/repositories/comment_repository.dart';
import 'package:unishare_mobile/features/post/domain/repositories/like_repository.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';
import 'package:unishare_mobile/features/post/domain/repositories/share_repository.dart';
import 'package:unishare_mobile/features/post/domain/usecases/add_comment.dart';
import 'package:unishare_mobile/features/post/domain/usecases/delete_comment.dart';
import 'package:unishare_mobile/features/post/domain/usecases/delete_post.dart';
import 'package:unishare_mobile/features/post/domain/usecases/create_post.dart';
import 'package:unishare_mobile/features/post/domain/usecases/share_post.dart';
import 'package:unishare_mobile/features/post/domain/usecases/update_post.dart';
import 'package:unishare_mobile/features/post/domain/usecases/sync_draft_queue.dart';
import 'package:unishare_mobile/features/post/domain/usecases/increment_view_count.dart';
import 'package:unishare_mobile/features/post/domain/usecases/toggle_like.dart';
import 'package:unishare_mobile/features/post/domain/usecases/watch_comments.dart';
import 'package:unishare_mobile/features/post/domain/usecases/watch_my_posts.dart';
import 'package:unishare_mobile/features/post/domain/usecases/watch_post.dart';

part 'post_repository_provider.g.dart';

@Riverpod(keepAlive: true)
PostFirestoreDatasource postFirestoreDatasource(Ref ref) {
  return PostFirestoreDatasource();
}

@Riverpod(keepAlive: true)
PostStorageDatasource postStorageDatasource(Ref ref) {
  return PostStorageDatasource();
}

@Riverpod(keepAlive: true)
FeedCache feedCache(Ref ref) => FeedCache();

@Riverpod(keepAlive: true)
TagWhitelistService tagWhitelistService(Ref ref) {
  return TagWhitelistService(
    cacheBox: Hive.box<dynamic>(tagWhitelistBoxName),
  );
}

@Riverpod(keepAlive: true)
PostRepository postRepository(Ref ref) {
  return PostRepositoryImpl(
    firestoreDatasource: ref.watch(postFirestoreDatasourceProvider),
    storageDatasource: ref.watch(postStorageDatasourceProvider),
    draftBox: Hive.box<PostDraftModel>('draft_queue'),
    feedCache: ref.watch(feedCacheProvider),
    tagWhitelistService: ref.watch(tagWhitelistServiceProvider),
  );
}

@Riverpod(keepAlive: true)
CreatePost createPostUseCase(Ref ref) {
  return CreatePost(ref.watch(postRepositoryProvider));
}

@Riverpod(keepAlive: true)
SyncDraftQueue syncDraftQueueUseCase(Ref ref) {
  return SyncDraftQueue(ref.watch(postRepositoryProvider));
}

// ---------------------------------------------------------------------------
// SPEC-0006 — Comment / Like providers
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
CommentFirestoreDatasource commentFirestoreDatasource(Ref ref) {
  return CommentFirestoreDatasource();
}

@Riverpod(keepAlive: true)
CommentRepository commentRepository(Ref ref) {
  return CommentRepositoryImpl(
    datasource: ref.watch(commentFirestoreDatasourceProvider),
  );
}

@Riverpod(keepAlive: true)
LikeRepository likeRepository(Ref ref) {
  return LikeRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
}

@Riverpod(keepAlive: true)
WatchPost watchPostUseCase(Ref ref) {
  return WatchPost(ref.watch(postRepositoryProvider));
}

@Riverpod(keepAlive: true)
WatchMyPosts watchMyPostsUseCase(Ref ref) {
  return WatchMyPosts(ref.watch(postRepositoryProvider));
}

@Riverpod(keepAlive: true)
WatchComments watchCommentsUseCase(Ref ref) {
  return WatchComments(ref.watch(commentRepositoryProvider));
}

@Riverpod(keepAlive: true)
AddComment addCommentUseCase(Ref ref) {
  return AddComment(ref.watch(commentRepositoryProvider));
}

@Riverpod(keepAlive: true)
DeleteComment deleteCommentUseCase(Ref ref) {
  return DeleteComment(ref.watch(commentRepositoryProvider));
}

@Riverpod(keepAlive: true)
ToggleLike toggleLikeUseCase(Ref ref) {
  return ToggleLike(ref.watch(likeRepositoryProvider));
}

@Riverpod(keepAlive: true)
IncrementViewCount incrementViewCountUseCase(Ref ref) {
  return IncrementViewCount(ref.watch(postRepositoryProvider));
}
// ---------------------------------------------------------------------------
// SPEC-0010 — Share providers
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
SharePlusDataSource sharePlusDatasource(Ref ref) => const SharePlusDataSource();

@Riverpod(keepAlive: true)
ShareRepository shareRepository(Ref ref) =>
    ShareRepositoryImpl(ref.watch(sharePlusDatasourceProvider));

@Riverpod(keepAlive: true)
SharePostUseCase sharePostUseCase(Ref ref) =>
    SharePostUseCase(ref.watch(shareRepositoryProvider));

// ---------------------------------------------------------------------------
// SPEC-0011 — Edit / Delete post providers
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
DeletePost deletePostUseCase(Ref ref) {
  return DeletePost(ref.watch(postRepositoryProvider));
}

@Riverpod(keepAlive: true)
UpdatePost updatePostUseCase(Ref ref) {
  return UpdatePost(ref.watch(postRepositoryProvider));
}
