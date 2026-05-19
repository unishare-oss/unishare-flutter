import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';

class PostFirestoreDatasource {
  late final _firestore = FirebaseFirestore.instance;

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
      'departmentId': draft.departmentId,
      'title': draft.title,
      'description': draft.description,
      'semester': draft.semester,
      'moduleNumber': draft.moduleNumber,
      'externalUrl': draft.externalUrl,
      'mediaUrls': mediaUrls,
      'mediaTypes': mediaTypes,
      if (mediaTypes.contains('pdf') || mediaTypes.contains('docx'))
        'summaryStatus': 'pending',
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

  Stream<List<Post>> watchPostsByAuthor(String authorId, {int limit = 50}) {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_docToPost).toList());
  }

  /// Server-side count aggregation — one round-trip, no documents transferred.
  Future<int> countPostsByAuthor(String authorId) async {
    final snap = await _firestore
        .collection('posts')
        .where('authorId', isEqualTo: authorId)
        .count()
        .get();
    return snap.count ?? 0;
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
      viewsCount: (data['viewsCount'] as num?)?.toInt() ?? 0,
      reactionCounts: Map<String, int>.from(
        ((data['reactionCounts'] as Map<String, dynamic>?) ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ),
      ),
      departmentId: data['departmentId'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      externalUrl: data['externalUrl'] as String?,
      codeSnippetUrl: data['codeSnippetUrl'] as String?,
      summary: data['summary'] as String?,
      summaryStatus: SummaryStatus.fromFirestore(
        data['summaryStatus'] as String?,
      ),
      summarizedAt: (data['summarizedAt'] as Timestamp?)?.toDate(),
    );
  }

  Stream<List<Post>> watchPostsByCourse(
    String courseId, {
    String? excludeId,
    int limit = 5,
  }) {
    return _firestore
        .collection('posts')
        .where('courseId', isEqualTo: courseId)
        .orderBy('createdAt', descending: true)
        .limit(limit + 1)
        .snapshots()
        .map(
          (s) => s.docs
              .map(_docToPost)
              .where((p) => p.id != excludeId)
              .take(limit)
              .toList(),
        );
  }

  Future<void> incrementViewCount(String postId) async {
    await _firestore.collection('posts').doc(postId).update({
      'viewsCount': FieldValue.increment(1),
    });
  }

  Future<void> updatePostSummary(
    String postId,
    String? summary,
    String summaryStatus,
  ) async {
    await _firestore.collection('posts').doc(postId).update({
      'summaryStatus': summaryStatus,
      'summary': summary ?? FieldValue.delete(),
      'summarizedAt': summaryStatus == 'done'
          ? FieldValue.serverTimestamp()
          : FieldValue.delete(),
    });
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  Future<void> updatePost({
    required String postId,
    required String title,
    required String description,
    required List<String> tags,
    String? externalUrl,
    required String moduleNumber,
    required bool descriptionChanged,
    required SummaryStatus? currentSummaryStatus,
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'description': description,
      'tags': tags,
      'externalUrl': externalUrl ?? FieldValue.delete(),
      'moduleNumber': moduleNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (descriptionChanged && currentSummaryStatus == SummaryStatus.done) {
      data['summaryStatus'] = 'pending';
      data['summary'] = FieldValue.delete();
      data['summarizedAt'] = FieldValue.delete();
    }
    await _firestore.collection('posts').doc(postId).update(data);
  }
}
