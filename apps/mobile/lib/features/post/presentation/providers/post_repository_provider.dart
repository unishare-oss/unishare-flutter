import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/comment_firestore_datasource.dart';
import '../../data/datasources/post_firestore_datasource.dart';
import '../../data/datasources/post_storage_datasource.dart';
import '../../data/models/post_draft_model.dart';
import '../../data/repositories/comment_repository_impl.dart';
import '../../data/repositories/like_repository_impl.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../domain/repositories/comment_repository.dart';
import '../../domain/repositories/like_repository.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/usecases/add_comment.dart';
import '../../domain/usecases/create_post.dart';
import '../../domain/usecases/sync_draft_queue.dart';
import '../../domain/usecases/toggle_like.dart';
import '../../domain/usecases/watch_comments.dart';
import '../../domain/usecases/watch_post.dart';

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
PostRepository postRepository(Ref ref) {
  return PostRepositoryImpl(
    firestoreDatasource: ref.watch(postFirestoreDatasourceProvider),
    storageDatasource: ref.watch(postStorageDatasourceProvider),
    draftBox: Hive.box<PostDraftModel>('draft_queue'),
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
WatchComments watchCommentsUseCase(Ref ref) {
  return WatchComments(ref.watch(commentRepositoryProvider));
}

@Riverpod(keepAlive: true)
AddComment addCommentUseCase(Ref ref) {
  return AddComment(ref.watch(commentRepositoryProvider));
}

@Riverpod(keepAlive: true)
ToggleLike toggleLikeUseCase(Ref ref) {
  return ToggleLike(ref.watch(likeRepositoryProvider));
}
