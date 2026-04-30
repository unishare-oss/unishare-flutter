import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/post_model.dart';

class PostFirestoreDataSource {
  PostFirestoreDataSource(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Cursor cache: maps page index to the last document of that page.
  final Map<int, DocumentSnapshot<Map<String, dynamic>>> _cursors = {};

  Future<List<PostModel>> getPostFeed({
    int page = 0,
    int pageSize = 20,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(pageSize);

    if (page > 0) {
      final cursor = _cursors[page - 1];
      if (cursor == null) {
        throw StateError(
          'Cannot fetch page $page: cursor for page ${page - 1} not cached. '
          'Pages must be fetched sequentially.',
        );
      }
      query = query.startAfterDocument(cursor);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _cursors[page] = snapshot.docs.last;
    }

    return _resolvePostsWithLikes(snapshot.docs);
  }

  Future<PostModel> getPost(String postId) async {
    final doc = await _firestore
        .collection('posts')
        .doc(postId)
        .get();

    if (!doc.exists) throw Exception('Post not found: $postId');

    final isLiked = await _isLikedByCurrentUser(postId);
    return PostModel.fromFirestore(doc, isLiked);
  }

  Future<void> toggleLike(String postId, {required bool liked}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    final likeRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(uid);

    if (liked) {
      await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
    } else {
      await likeRef.delete();
    }
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  Future<List<PostModel>> _resolvePostsWithLikes(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final uid = _auth.currentUser?.uid;

    return Future.wait(
      docs.map((doc) async {
        final isLiked = uid != null
            ? (await _firestore
                    .collection('posts')
                    .doc(doc.id)
                    .collection('likes')
                    .doc(uid)
                    .get())
                .exists
            : false;
        return PostModel.fromFirestore(doc, isLiked);
      }),
    );
  }

  Future<bool> _isLikedByCurrentUser(String postId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final doc = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(uid)
        .get();
    return doc.exists;
  }
}
