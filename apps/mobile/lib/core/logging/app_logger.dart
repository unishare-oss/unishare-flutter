import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Thin application-wide logger. Wraps [debugPrint] in debug builds and
/// [FirebaseCrashlytics.recordError] in release so production failures are
/// captured consistently instead of being lost to `debugPrint` (which is
/// a no-op in release builds).
///
/// The repo convention is that production error paths use this instead of
/// raw `debugPrint`/`print` — keep call sites short so adding context to a
/// failure remains cheap.
class AppLogger {
  AppLogger._();

  /// Non-fatal application error. In debug, dumps to console; in release,
  /// records to Crashlytics (non-fatal so it doesn't terminate the app).
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint(
        '[error] $message'
        '${error != null ? ': $error' : ''}'
        '${stackTrace != null ? '\n$stackTrace' : ''}',
      );
      return;
    }
    // Crashlytics is initialized in `core/firebase/firebase_init.dart`.
    // Recording a non-fatal preserves app continuity while still surfacing
    // the failure to the dashboard.
    FirebaseCrashlytics.instance.recordError(
      error ?? message,
      stackTrace,
      reason: message,
      fatal: false,
    );
  }

  /// Informational message. Debug-only; release builds drop it on the floor
  /// to keep Crashlytics signal-to-noise high.
  static void info(String message) {
    if (kDebugMode) debugPrint('[info] $message');
  }
}
