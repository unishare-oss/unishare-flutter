// TODO(flutter-engineer): implement per SPEC-0006
// Run: dart run build_runner build --delete-conflicting-outputs

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/comment.dart';
// Needed when implementing: import '../../domain/usecases/watch_comments.dart';

part 'comments_provider.g.dart';

@riverpod
Stream<List<Comment>> comments(Ref ref, String postId) {
  throw UnimplementedError('TODO(flutter-engineer): implement per SPEC-0006');
}
