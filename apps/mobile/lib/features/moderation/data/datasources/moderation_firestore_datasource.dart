import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:unishare_mobile/features/moderation/data/models/pending_post_model.dart';
import 'package:unishare_mobile/features/moderation/domain/entities/pending_post.dart';

class ModerationFirestoreDatasource {
  ModerationFirestoreDatasource({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseFunctions _functions;
  final _db = FirebaseFirestore.instance;

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

  Stream<List<PendingPost>> watchRejectedPosts() {
    return _db
        .collection('posts')
        .where('status', isEqualTo: 'rejected')
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
    await _functions.httpsCallable('handleModerationAction').call({
      'postId': postId,
      'action': 'approve',
    });
  }

  Future<void> rejectPost(String postId, String reason) async {
    await _functions.httpsCallable('handleModerationAction').call({
      'postId': postId,
      'action': 'reject',
      'reason': reason,
    });
  }

  Future<void> restorePost(String postId) async {
    await _functions.httpsCallable('handleModerationAction').call({
      'postId': postId,
      'action': 'restore',
    });
  }
}
