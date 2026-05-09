import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unishare_mobile/features/saved/data/models/saved_post_dto.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post_snapshot.dart';

class SavedPostFirestoreDatasource {
  SavedPostFirestoreDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('savedPosts');

  Stream<List<SavedPost>> watchAll(String uid) {
    return _col(uid)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_docToEntity).toList());
  }

  Future<void> save(
    String uid,
    String postId,
    SavedPostSnapshot snapshot,
  ) async {
    final ref = _col(uid).doc(postId);
    final existing = await ref.get();
    if (existing.exists) return;
    await ref.set({
      'postId': postId,
      'savedAt': Timestamp.now(),
      'title': snapshot.title,
      'authorName': snapshot.authorName,
      'authorAvatar': snapshot.authorAvatar,
      'courseId': snapshot.courseId,
      'postType': snapshot.postType,
      'tags': snapshot.tags,
      'commentsCount': snapshot.commentsCount,
    });
  }

  Future<void> unsave(String uid, String postId) =>
      _col(uid).doc(postId).delete();

  Stream<bool> watchSaved(String uid, String postId) {
    return _col(uid).doc(postId).snapshots().map((doc) => doc.exists);
  }

  Future<void> mergeAll(String uid, List<SavedPost> saves) async {
    if (saves.isEmpty) return;
    final existingSnap = await _col(uid).get();
    final existingIds = existingSnap.docs.map((d) => d.id).toSet();
    final toWrite = saves.where((s) => !existingIds.contains(s.postId)).toList();
    if (toWrite.isEmpty) return;
    final batch = _firestore.batch();
    for (final save in toWrite) {
      batch.set(_col(uid).doc(save.postId), {
        'postId': save.postId,
        'savedAt': Timestamp.fromDate(save.savedAt),
        'title': save.snapshot.title,
        'authorName': save.snapshot.authorName,
        'authorAvatar': save.snapshot.authorAvatar,
        'courseId': save.snapshot.courseId,
        'postType': save.snapshot.postType,
        'tags': save.snapshot.tags,
        'commentsCount': save.snapshot.commentsCount,
      });
    }
    await batch.commit();
  }

  SavedPost _docToEntity(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final ts = data['savedAt'] as Timestamp;
    final dto = SavedPostDto.fromJson({
      ...data,
      'savedAt': ts.toDate().toIso8601String(),
    });
    return dto.toEntity();
  }
}
