import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/post.dart';
import '../../domain/entities/post_draft.dart';

class PostFirestoreDatasource {
  final _firestore = FirebaseFirestore.instance;

  Future<void> createPost({
    required PostDraft draft,
    required List<String> mediaUrls,
    required List<String> mediaTypes,
    required String authorName,
    required String authorAvatar,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('not_authenticated');

    final now = Timestamp.now();
    await _firestore.collection('posts').doc(draft.id).set({
      'authorId': uid,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'title': draft.title,
      'body': draft.body,
      'mediaUrls': mediaUrls,
      'mediaTypes': mediaTypes,
      'tags': draft.tags,
      'likesCount': 0,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Stream<Post> watchPost(String postId) {
    return _firestore.collection('posts').doc(postId).snapshots().map((doc) {
      if (!doc.exists) throw StateError('post_not_found');
      final data = doc.data()!;
      return Post(
        id: doc.id,
        authorId: data['authorId'] as String,
        authorName: data['authorName'] as String,
        authorAvatar: data['authorAvatar'] as String,
        title: data['title'] as String,
        body: data['body'] as String,
        mediaUrls: List<String>.from(data['mediaUrls'] as List? ?? []),
        mediaTypes: List<String>.from(data['mediaTypes'] as List? ?? []),
        tags: List<String>.from(data['tags'] as List? ?? []),
        likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
    });
  }
}
