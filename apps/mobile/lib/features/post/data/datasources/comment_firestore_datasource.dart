// TODO(flutter-engineer): implement per SPEC-0006
// Imports needed when implementing:
//   import 'package:cloud_firestore/cloud_firestore.dart';
//   import 'package:firebase_auth/firebase_auth.dart';
//   import '../models/comment_dto.dart';

import '../../domain/entities/comment.dart';

class CommentFirestoreDatasource {
  /// Streams posts/{postId}/comments ordered by createdAt ascending.
  Stream<List<Comment>> watchComments(String postId) {
    throw UnimplementedError('TODO(flutter-engineer): implement per SPEC-0006');
  }

  /// Writes a new comment document to posts/{postId}/comments.
  Future<void> addComment(String postId, String body) {
    throw UnimplementedError('TODO(flutter-engineer): implement per SPEC-0006');
  }
}
