import 'package:unishare_mobile/features/moderation/data/datasources/moderation_firestore_datasource.dart';
import 'package:unishare_mobile/features/moderation/domain/entities/pending_post.dart';
import 'package:unishare_mobile/features/moderation/domain/repositories/moderation_repository.dart';

class ModerationRepositoryImpl implements ModerationRepository {
  const ModerationRepositoryImpl({required this.datasource});

  final ModerationFirestoreDatasource datasource;

  @override
  Stream<List<PendingPost>> getPendingPosts() => datasource.watchPendingPosts();

  @override
  Future<void> approvePost(String postId) => datasource.approvePost(postId);

  @override
  Future<void> rejectPost(String postId, String reason) =>
      datasource.rejectPost(postId, reason);
}
