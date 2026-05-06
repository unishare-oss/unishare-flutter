import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/comment.dart';
import '../models/comment_dto.dart';

class CommentFirestoreDatasource {
  final _firestore = FirebaseFirestore.instance;

  Stream<List<Comment>> watchComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => CommentDto.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }).toEntity(),
              )
              .toList(),
        );
  }

  Future<void> addComment(String postId, String body) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('not_authenticated');

    final ref = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc();

    await ref.set({
      'id': ref.id,
      'authorId': user.uid,
      'authorName': user.displayName ?? '',
      'authorAvatar': user.photoURL ?? '',
      'body': body,
      'createdAt': Timestamp.now(),
    });
  }
}
