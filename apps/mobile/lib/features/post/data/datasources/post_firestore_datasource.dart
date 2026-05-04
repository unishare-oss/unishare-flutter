import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/post_draft.dart';

class PostFirestoreDatasource {
  final _firestore = FirebaseFirestore.instance;

  Future<void> createPost({
    required PostDraft draft,
    required List<String> mediaUrls,
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
      'tags': draft.tags,
      'likesCount': 0,
      'createdAt': now,
      'updatedAt': now,
    });
  }
}
