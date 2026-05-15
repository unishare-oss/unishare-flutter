import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';

/// Unbounded post count for a given user, via the domain repository's
/// aggregation-backed `countPostsByAuthor`. One round-trip, no documents.
final userPostsCountProvider = FutureProvider.autoDispose.family<int, String>((
  ref,
  uid,
) {
  final repo = ref.watch(postRepositoryProvider);
  return repo.countPostsByAuthor(uid);
});

/// Live comment count for a given user. Goes through the auth repository so
/// the presentation layer doesn't reach into the Firestore datasource.
final userCommentsCountProvider = StreamProvider.autoDispose
    .family<int, String>((ref, uid) {
      final repo = ref.watch(authRepositoryProvider);
      return repo.watchCommentCountByAuthor(uid);
    });
