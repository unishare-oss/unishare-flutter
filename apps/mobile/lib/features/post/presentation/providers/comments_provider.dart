import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/post/domain/entities/comment.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';

part 'comments_provider.g.dart';

@riverpod
Stream<List<Comment>> comments(Ref ref, String postId) =>
    ref.watch(watchCommentsUseCaseProvider)(postId);
