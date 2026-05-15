import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unishare_mobile/features/notifications/data/models/notification_model.dart';
import 'package:unishare_mobile/features/notifications/domain/entities/notification_item.dart';

class NotificationFirestoreDatasource {
  NotificationFirestoreDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _notificationsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  CollectionReference<Map<String, dynamic>> _fcmTokensRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('fcmTokens');

  // ---------------------------------------------------------------------------
  // Watch notifications
  // ---------------------------------------------------------------------------

  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _notificationsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => NotificationModel.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }).toDomain(),
              )
              .toList(),
        );
  }

  // ---------------------------------------------------------------------------
  // Mark as read
  // ---------------------------------------------------------------------------

  Future<void> markAsRead(String userId, String notificationId) {
    return _notificationsRef(
      userId,
    ).doc(notificationId).update({'isRead': true});
  }

  // ---------------------------------------------------------------------------
  // Mark all as read (batched writes, max 500 per batch)
  // ---------------------------------------------------------------------------

  Future<void> markAllAsRead(String userId) async {
    final snap = await _notificationsRef(
      userId,
    ).where('isRead', isEqualTo: false).get();

    if (snap.docs.isEmpty) return;

    // Split into batches of 500 to stay within Firestore limits.
    const batchSize = 500;
    final docs = snap.docs;
    for (var i = 0; i < docs.length; i += batchSize) {
      final batch = _firestore.batch();
      final end = (i + batchSize < docs.length) ? i + batchSize : docs.length;
      for (final doc in docs.sublist(i, end)) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    }
  }

  // ---------------------------------------------------------------------------
  // FCM token management
  // ---------------------------------------------------------------------------

  /// Registers or refreshes the FCM token for [userId].
  ///
  /// Uses [token.hashCode.toRadixString(16)] as the document ID (avoids adding
  /// the `crypto` dependency). The document is written with set-merge so that
  /// `createdAt` is preserved on refresh and only `updatedAt` changes.
  Future<void> registerFcmToken(
    String userId,
    String token,
    String platform,
  ) async {
    final tokenHash = token.hashCode.toRadixString(16);
    final ref = _fcmTokensRef(userId).doc(tokenHash);
    final now = Timestamp.now();

    await ref.set({
      'token': token,
      'platform': platform,
      'updatedAt': now,
      'createdAt': now,
    }, SetOptions(merge: true));
  }

  /// Removes the FCM token document for [token] (called on sign-out).
  Future<void> removeFcmToken(String userId, String token) async {
    final tokenHash = token.hashCode.toRadixString(16);
    await _fcmTokensRef(userId).doc(tokenHash).delete();
  }
}
