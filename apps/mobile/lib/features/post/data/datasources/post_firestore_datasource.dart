import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';

class PostFirestoreDatasource {
  final _firestore = FirebaseFirestore.instance;

  Future<void> createPost({
    required PostDraft draft,
    required List<String> mediaUrls,
    required List<String> mediaTypes,
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
      'mediaTypes': mediaTypes,
      'codeSnippetUrl': codeSnippetUrl,
      'tags': draft.tags,
      'likesCount': 0,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Stream<List<Post>> watchFeed({int limit = 20}) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_docToPost).toList());
  }

  Stream<Post> watchPost(String postId) {
    return _firestore.collection('posts').doc(postId).snapshots().map((doc) {
      if (!doc.exists) throw StateError('post_not_found');
      return _docToPost(doc);
    });
  }

  Post _docToPost(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Post(
      id: doc.id,
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String? ?? '',
      authorAvatar: data['authorAvatar'] as String? ?? '',
      postType: PostType.values.byName(
        data['postType'] as String? ?? PostType.lectureNote.name,
      ),
      year: (data['year'] as num?)?.toInt() ?? 1,
      courseId: data['courseId'] as String? ?? '',
      title: data['title'] as String,
      description: data['description'] as String? ?? '',
      postingIdentity: PostingIdentity.values.byName(
        data['postingIdentity'] as String? ?? PostingIdentity.named.name,
      ),
      semester: (data['semester'] as num?)?.toInt() ?? 1,
      moduleNumber: data['moduleNumber'] as String? ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] as List? ?? []),
      mediaTypes: List<String>.from(data['mediaTypes'] as List? ?? []),
      tags: List<String>.from(data['tags'] as List? ?? []),
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      externalUrl: data['externalUrl'] as String?,
      codeSnippetUrl: data['codeSnippetUrl'] as String?,
    );
  }
}
