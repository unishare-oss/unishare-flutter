import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FcmService {
  /// Initialises FCM for the signed-in [userId].
  ///
  /// - Requests notification permission on iOS.
  /// - Retrieves the initial token and calls [onTokenRegistered].
  /// - Subscribes to token refresh and calls [onTokenRegistered] on each
  ///   refresh.
  /// - Sets up a foreground message handler; the Firestore stream auto-updates
  ///   so no explicit action is needed here.
  ///
  /// This is a no-op on web: FCM push via VAPID is deferred per SPEC-0001.
  static Future<void> init({
    required String userId,
    required Future<void> Function(String token, String platform)
    onTokenRegistered,
  }) async {
    if (kIsWeb) return;

    // Request permission (required on iOS; harmless on Android).
    await FirebaseMessaging.instance.requestPermission();

    // Retrieve the current registration token.
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await onTokenRegistered(token, platform);
    }

    // Re-register whenever the token is rotated by FCM.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await onTokenRegistered(newToken, platform);
    });

    // Foreground message handler — the Firestore real-time stream refreshes
    // automatically when a Cloud Function writes a new notification document,
    // so no additional UI action is needed here.
    FirebaseMessaging.onMessage.listen((_) {
      // No-op: Firestore stream handles the UI update.
    });
  }

  /// Removes the current device token from Firestore and deletes it from FCM.
  ///
  /// Call this on sign-out so Cloud Functions stop pushing to this device.
  ///
  /// This is a no-op on web.
  static Future<void> removeToken({
    required String userId,
    required Future<void> Function(String token) onTokenRemoved,
  }) async {
    if (kIsWeb) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await onTokenRemoved(token);
    }
    await FirebaseMessaging.instance.deleteToken();
  }
}
