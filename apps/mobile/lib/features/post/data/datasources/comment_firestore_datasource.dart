import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:unishare_mobile/features/post/domain/entities/comment.dart';
import 'package:unishare_mobile/features/post/data/models/comment_dto.dart';

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

  Future<void> deleteComment(String postId, String commentId) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final col = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments');
    final batch = _firestore.batch();

    batch.delete(col.doc(commentId));

    if (currentUid != null) {
      final replies = await col.where('parentId', isEqualTo: commentId).get();
      for (final doc in replies.docs) {
        if (doc.data()['authorId'] == currentUid) {
          batch.delete(doc.reference);
        }
      }
    }

    await batch.commit();
  }

  /// Server-side count of comments authored by [uid] across all posts.
  /// One aggregation round-trip — no documents transferred.
  Future<int> countCommentsByAuthor(String uid) async {
    final snap = await _firestore
        .collectionGroup('comments')
        .where('authorId', isEqualTo: uid)
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<void> addComment(
    String postId,
    String body, {
    String? parentId,
  }) async {
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
      'parentId': ?parentId,
    });
  }
}
