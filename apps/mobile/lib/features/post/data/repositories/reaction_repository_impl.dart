import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:unishare_mobile/features/post/domain/repositories/reaction_repository.dart';

class ReactionRepositoryImpl implements ReactionRepository {
  ReactionRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<void> toggleReaction(String postId, String reactionType) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('not_authenticated');

    final reactionRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('reactions')
        .doc(uid);
    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(reactionRef);
      final existing = snap.exists
          ? (snap.data()?[reactionType] as bool? ?? false)
          : false;

      if (existing) {
        // Remove the reaction field from the user doc.
        tx.set(
          reactionRef,
          {reactionType: FieldValue.delete()},
          SetOptions(merge: true),
        );
        tx.update(postRef, {
          'reactionCounts.$reactionType': FieldValue.increment(-1),
        });
      } else {
        // Add the reaction field to the user doc.
        tx.set(
          reactionRef,
          {reactionType: true},
          SetOptions(merge: true),
        );
        tx.update(postRef, {
          'reactionCounts.$reactionType': FieldValue.increment(1),
        });
      }
    });
  }

  @override
  Stream<Set<String>> watchUserReactions(String postId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const {});

    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('reactions')
        .doc(uid)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return const <String>{};
      final data = snap.data() ?? {};
      return data.entries
          .where((e) => e.value == true)
          .map((e) => e.key)
          .toSet();
    });
  }
}
