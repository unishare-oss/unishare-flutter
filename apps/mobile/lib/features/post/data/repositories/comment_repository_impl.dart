// TODO(flutter-engineer): implement per SPEC-0006

import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../datasources/comment_firestore_datasource.dart';

class CommentRepositoryImpl implements CommentRepository {
  const CommentRepositoryImpl({required this.datasource});

  final CommentFirestoreDatasource datasource;

  @override
  Stream<List<Comment>> watchComments(String postId) =>
      datasource.watchComments(postId);

  @override
  Future<void> addComment(String postId, String body) =>
      datasource.addComment(postId, body);
}
