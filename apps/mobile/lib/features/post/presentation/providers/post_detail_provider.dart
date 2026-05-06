import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/post.dart';
import 'post_repository_provider.dart';

part 'post_detail_provider.g.dart';

@riverpod
class PostDetail extends _$PostDetail {
  @override
  FutureOr<Post> build(String postId, {Post? seed}) {
    final watchPost = ref.watch(watchPostUseCaseProvider);
    final stream = watchPost(postId);
    final completer = Completer<Post>();

    final sub = stream.listen(
      (post) {
        if (!completer.isCompleted) completer.complete(post);
        state = AsyncData(post);
      },
      onError: (Object e, StackTrace st) {
        if (!completer.isCompleted) completer.completeError(e, st);
        if (!state.hasValue) state = AsyncError(e, st);
      },
      cancelOnError: false,
    );
    ref.onDispose(sub.cancel);

    if (seed != null) return seed; // warm-start: instant render
    return completer.future; // cold-start: wait for first snapshot
  }
}