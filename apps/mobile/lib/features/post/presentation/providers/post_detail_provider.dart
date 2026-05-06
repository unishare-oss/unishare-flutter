// TODO(flutter-engineer): implement per SPEC-0006
// Run: dart run build_runner build --delete-conflicting-outputs

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/post.dart';
// Needed when implementing: import '../../domain/usecases/watch_post.dart';

part 'post_detail_provider.g.dart';

// AsyncNotifier family keyed on (postId, seed).
//
// Build logic:
//   1. If seed != null, emit seed immediately as state (zero-latency warm-start).
//   2. Open WatchPost(postId) stream regardless of seed.
//   3. On first/subsequent stream events, overwrite state.
//   4. On stream error, set AsyncError (do not discard seed if stream fails).
@riverpod
class PostDetail extends _$PostDetail {
  @override
  Future<Post> build(String postId, {Post? seed}) {
    throw UnimplementedError('TODO(flutter-engineer): implement per SPEC-0006');
  }
}
