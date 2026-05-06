import 'package:unishare_mobile/features/post/domain/entities/comment.dart';
import 'package:unishare_mobile/features/post/domain/repositories/comment_repository.dart';
import 'package:unishare_mobile/features/post/data/datasources/comment_firestore_datasource.dart';

class CommentRepositoryImpl implements CommentRepository {
  CommentRepositoryImpl({required this.datasource});

  final CommentFirestoreDatasource datasource;

  @override
  Stream<List<Comment>> watchComments(String postId) =>
      datasource.watchComments(postId);

  @override
  Future<void> addComment(String postId, String body) =>
      datasource.addComment(postId, body);
}
