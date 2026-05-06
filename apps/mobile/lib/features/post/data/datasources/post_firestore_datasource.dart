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
    String? codeSnippetUrl,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('not_authenticated');

    final now = Timestamp.now();
    await _firestore.collection('posts').doc(draft.id).set({
      'authorId': uid,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'postingIdentity': draft.postingIdentity.name,
      'postType': draft.postType.name,
      'year': draft.year,
      'courseId': draft.courseId,
      'title': draft.title,
      'description': draft.description,
      'semester': draft.semester,
      'moduleNumber': draft.moduleNumber,
      'externalUrl': draft.externalUrl,
      'mediaUrls': mediaUrls,
      'codeSnippetUrl': codeSnippetUrl,
      'tags': draft.tags,
      'likesCount': 0,
      'createdAt': now,
      'updatedAt': now,
    });
  }
}
