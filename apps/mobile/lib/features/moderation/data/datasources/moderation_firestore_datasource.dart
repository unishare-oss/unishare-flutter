import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:unishare_mobile/features/moderation/data/models/pending_post_model.dart';
import 'package:unishare_mobile/features/moderation/domain/entities/pending_post.dart';

class ModerationFirestoreDatasource {
  late final _db = FirebaseFirestore.instance;

  Stream<List<PendingPost>> watchPendingPosts() {
    return _db
        .collection('posts')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(PendingPostModel.fromFirestore)
              .map((m) => m.toEntity())
              .toList(),
        );
  }

  Future<void> approvePost(String postId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('not_authenticated');
    await _db.collection('posts').doc(postId).update({
      'status': 'approved',
      'moderatedBy': uid,
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectPost(String postId, String reason) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('not_authenticated');
    await _db.collection('posts').doc(postId).update({
      'status': 'rejected',
      'rejectionReason': reason,
      'moderatedBy': uid,
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }
}
