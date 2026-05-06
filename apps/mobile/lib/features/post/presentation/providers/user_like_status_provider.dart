// TODO(flutter-engineer): implement per SPEC-0006
// Run: dart run build_runner build --delete-conflicting-outputs

import 'package:riverpod_annotation/riverpod_annotation.dart';

// Needed when implementing: import '../../domain/repositories/like_repository.dart';

part 'user_like_status_provider.g.dart';

// Emits true when posts/{postId}/likes/{currentUserId} exists.
// Emits false when absent or when the current user is a guest.
@riverpod
Stream<bool> userLikeStatus(Ref ref, String postId) {
  throw UnimplementedError('TODO(flutter-engineer): implement per SPEC-0006');
}
