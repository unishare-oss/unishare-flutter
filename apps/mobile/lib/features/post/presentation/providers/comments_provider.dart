import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/comment.dart';
import 'post_repository_provider.dart';

part 'comments_provider.g.dart';

@riverpod
Stream<List<Comment>> comments(Ref ref, String postId) =>
    ref.watch(watchCommentsUseCaseProvider)(postId);
