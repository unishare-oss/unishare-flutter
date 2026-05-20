import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/post/domain/entities/comment.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';

part 'comments_provider.g.dart';

@riverpod
Stream<List<Comment>> comments(Ref ref, String postId) =>
    ref.watch(watchCommentsUseCaseProvider)(postId);

typedef ReplyTarget = ({String id, String name});

@riverpod
class ReplyState extends _$ReplyState {
  @override
  ReplyTarget? build(String postId) => null;

  void startReply(String id, String name) => state = (id: id, name: name);
  void cancel() => state = null;
}
