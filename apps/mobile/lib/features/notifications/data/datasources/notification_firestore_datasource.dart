import 'dart:convert' show utf8;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart' show sha256;

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

  /// Returns the SHA-256 hex digest of [token].
  ///
  /// Per SPEC-0001 § Firestore Schema, `{tokenHash}` is the SHA-256 hex
  /// digest of the raw FCM token string.  Using SHA-256 (via the `crypto`
  /// package) gives a stable, collision-resistant, process-independent ID —
  /// unlike `token.hashCode` which is process-local and can collide.
  String _tokenHash(String token) {
    final bytes = utf8.encode(token);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Registers or refreshes the FCM token for [userId].
  ///
  /// Per SPEC-0001 § Firestore Schema:
  /// - `createdAt` records the FIRST registration and must not be overwritten
  ///   on subsequent calls.
  /// - `updatedAt` is refreshed on every app start / token rotation.
  ///
  /// A transaction is used so that the read-then-conditional-write is atomic.
  Future<void> registerFcmToken(
    String userId,
    String token,
    String platform,
  ) async {
    final tokenHash = _tokenHash(token);
    final ref = _fcmTokensRef(userId).doc(tokenHash);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final now = FieldValue.serverTimestamp();

      if (!snap.exists) {
        // First registration: write both timestamps.
        tx.set(ref, {
          'token': token,
          'platform': platform,
          'createdAt': now,
          'updatedAt': now,
        });
      } else {
        // Subsequent refresh: only bump updatedAt; leave createdAt alone.
        tx.update(ref, {
          'token': token,
          'platform': platform,
          'updatedAt': now,
        });
      }
    });
  }

  /// Removes the FCM token document for [token] (called on sign-out).
  Future<void> removeFcmToken(String userId, String token) async {
    final tokenHash = _tokenHash(token);
    await _fcmTokensRef(userId).doc(tokenHash).delete();
  }
}
