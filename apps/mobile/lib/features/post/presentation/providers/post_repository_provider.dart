import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/post/data/datasources/post_firestore_datasource.dart';
import 'package:unishare_mobile/features/post/data/datasources/post_storage_datasource.dart';
import 'package:unishare_mobile/features/post/data/models/post_draft_model.dart';
import 'package:unishare_mobile/features/post/data/repositories/post_repository_impl.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';
import 'package:unishare_mobile/features/post/domain/usecases/create_post.dart';
import 'package:unishare_mobile/features/post/domain/usecases/sync_draft_queue.dart';

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
