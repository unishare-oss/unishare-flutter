import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';

part 'profile_stats_provider.g.dart';

/// Unbounded post count for a given user, via the domain repository's
/// aggregation-backed `countPostsByAuthor`. One round-trip, no documents.
@riverpod
Future<int> userPostsCount(Ref ref, String uid) {
  return ref.watch(postRepositoryProvider).countPostsByAuthor(uid);
}

/// Comment count for a given user. One-shot Firestore aggregation read
/// (not streamed) — cheap on profile load. Goes through CommentRepository
/// since comment stats belong to the comment domain, not auth.
@riverpod
Future<int> userCommentsCount(Ref ref, String uid) {
  return ref.watch(commentRepositoryProvider).countCommentsByAuthor(uid);
}
