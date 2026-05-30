import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/moderation/data/datasources/moderation_firestore_datasource.dart';
import 'package:unishare_mobile/features/moderation/data/repositories/moderation_repository_impl.dart';
import 'package:unishare_mobile/features/moderation/domain/repositories/moderation_repository.dart';
import 'package:unishare_mobile/features/moderation/domain/usecases/approve_post.dart';
import 'package:unishare_mobile/features/moderation/domain/usecases/get_pending_posts.dart';
import 'package:unishare_mobile/features/moderation/domain/usecases/get_rejected_posts.dart';
import 'package:unishare_mobile/features/moderation/domain/usecases/reject_post.dart';
import 'package:unishare_mobile/features/moderation/domain/usecases/restore_post.dart';

part 'moderation_repository_provider.g.dart';

@Riverpod(keepAlive: true)
ModerationFirestoreDatasource moderationFirestoreDatasource(Ref ref) =>
    ModerationFirestoreDatasource();

@Riverpod(keepAlive: true)
ModerationRepository moderationRepository(Ref ref) => ModerationRepositoryImpl(
  datasource: ref.watch(moderationFirestoreDatasourceProvider),
);

@Riverpod(keepAlive: true)
GetPendingPosts getPendingPostsUseCase(Ref ref) =>
    GetPendingPosts(ref.watch(moderationRepositoryProvider));

@Riverpod(keepAlive: true)
GetRejectedPosts getRejectedPostsUseCase(Ref ref) =>
    GetRejectedPosts(ref.watch(moderationRepositoryProvider));

@Riverpod(keepAlive: true)
ApprovePost approvePostUseCase(Ref ref) =>
    ApprovePost(ref.watch(moderationRepositoryProvider));

@Riverpod(keepAlive: true)
RejectPost rejectPostUseCase(Ref ref) =>
    RejectPost(ref.watch(moderationRepositoryProvider));

@Riverpod(keepAlive: true)
RestorePost restorePostUseCase(Ref ref) =>
    RestorePost(ref.watch(moderationRepositoryProvider));
