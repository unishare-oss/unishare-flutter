// `dart:io` is only available on native platforms.  We import it conditionally
// so that web builds — which cannot resolve dart:io at compile time — still
// compile cleanly.  The kIsWeb guard inside every method keeps the runtime
// behaviour identical on all platforms.
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:unishare_mobile/core/logging/app_logger.dart';

// Conditional import: on web the stub supplies a no-op `currentPlatformLabel`.
import 'package:unishare_mobile/core/firebase/platform_stub.dart'
    if (dart.library.io) 'package:unishare_mobile/core/firebase/platform_native.dart'
    as platform;

/// Pending deep-link tap delivered via [onMessageTapped].
///
/// [targetType] mirrors SPEC-0001 § Payload: `'post'` or `'request'`.
class FcmTapEvent {
  const FcmTapEvent({required this.targetType, required this.targetId});

  final String targetType;
  final String targetId;
}

/// Manages the FCM registration lifecycle for a single signed-in user.
///
/// Use [init] on sign-in and [dispose] on sign-out.  Calling [init] again
/// (e.g. after sign-out → sign-in as a different user) cancels the previous
/// subscriptions before binding to the new UID, so token-refresh events are
/// always routed to the currently authenticated account.
class FcmService {
  FcmService._();

  static final FcmService _instance = FcmService._();

  /// Singleton accessor — callers share one set of stream subscriptions.
  static FcmService get instance => _instance;

  // ---------------------------------------------------------------------------
  // Deep-link stream
  // ---------------------------------------------------------------------------

  final _tapController = StreamController<FcmTapEvent>.broadcast();

  /// Fires whenever the user taps a push notification (cold-start or
  /// background-tap).  The App widget listens to this and delegates to
  /// GoRouter.
  Stream<FcmTapEvent> get onMessageTapped => _tapController.stream;

  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Initialises FCM for the signed-in [userId].
  ///
  /// Cancels any subscriptions left over from a previous [init] call so that
  /// token-refresh events are always routed to the currently signed-in account.
  ///
  /// On web this is a no-op (FCM push via VAPID is deferred per SPEC-0001);
  /// the Firestore in-app stream continues to work normally.
  Future<void> init({
    required String userId,
    required Future<void> Function(String token, String platform)
    onTokenRegistered,
  }) async {
    if (kIsWeb) return;

    // Cancel subscriptions from any previous sign-in before rebinding.
    await _cancelSubscriptions();

    try {
      // Request permission (required on iOS; harmless on Android).
      await FirebaseMessaging.instance.requestPermission();

      // Retrieve the current registration token.
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await onTokenRegistered(token, platform.currentPlatformLabel);
      }

      // Re-register whenever the token is rotated by FCM.
      _subscriptions.add(
        FirebaseMessaging.instance.onTokenRefresh.listen(
          (newToken) async {
            try {
              await onTokenRegistered(newToken, platform.currentPlatformLabel);
            } catch (e, st) {
              AppLogger.error(
                'FCM token refresh registration failed',
                error: e,
                stackTrace: st,
              );
            }
          },
          onError: (Object e, StackTrace st) {
            AppLogger.error(
              'FCM onTokenRefresh stream error',
              error: e,
              stackTrace: st,
            );
          },
        ),
      );

      // Foreground message handler — the Firestore real-time stream refreshes
      // automatically when a Cloud Function writes a new notification document,
      // so no additional UI action is needed here.
      _subscriptions.add(
        FirebaseMessaging.onMessage.listen(
          (_) {
            // No-op: Firestore stream handles the UI update.
          },
          onError: (Object e, StackTrace st) {
            AppLogger.error(
              'FCM onMessage stream error',
              error: e,
              stackTrace: st,
            );
          },
        ),
      );

      // Background-tap: user tapped a notification while the app was in the
      // background (but already running).
      _subscriptions.add(
        FirebaseMessaging.onMessageOpenedApp.listen(
          _handleTap,
          onError: (Object e, StackTrace st) {
            AppLogger.error(
              'FCM onMessageOpenedApp stream error',
              error: e,
              stackTrace: st,
            );
          },
        ),
      );

      // Cold-start tap: user tapped a notification that launched the app.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _handleTap(initial);
      }
    } catch (e, st) {
      // Permission denial or token fetch failure — degrade to in-app stream
      // only and log once.  Do NOT rethrow; a startup crash here is worse
      // than missing push notifications.
      AppLogger.error(
        'FCM init failed — falling back to in-app stream only',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Removes the current device token from Firestore and deletes it from FCM.
  ///
  /// Call this on sign-out BEFORE the auth state clears so the Firestore write
  /// can still be attributed to the correct UID.
  ///
  /// This is a no-op on web.
  Future<void> removeToken({
    required String userId,
    required Future<void> Function(String token) onTokenRemoved,
  }) async {
    if (kIsWeb) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await onTokenRemoved(token);
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (e, st) {
      AppLogger.error('FCM removeToken failed', error: e, stackTrace: st);
    }
  }

  /// Cancels all active stream subscriptions.
  ///
  /// Called automatically at the start of each [init] and should be called
  /// explicitly on sign-out (before [removeToken]) so the token-refresh
  /// listener cannot race with the removal.
  Future<void> dispose() => _cancelSubscriptions();

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _cancelSubscriptions() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
  }

  void _handleTap(RemoteMessage message) {
    final data = message.data;
    final targetType = data['targetType'] as String?;
    final targetId = data['targetId'] as String?;
    if (targetType != null && targetId != null) {
      _tapController.add(
        FcmTapEvent(targetType: targetType, targetId: targetId),
      );
    }
  }
}
