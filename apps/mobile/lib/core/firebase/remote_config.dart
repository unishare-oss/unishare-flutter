import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Feature-flag keys backed by Firebase Remote Config. Keep these in sync with
/// the parameter keys published in the Firebase Console (Run -> Remote Config).
class AppFlags {
  AppFlags._();

  static const aiSummary = 'ai_summary_enabled';
  static const aiChat = 'ai_chat_enabled';
  static const hybridSearch = 'hybrid_search_enabled';
  static const requests = 'requests_enabled';
  static const achievements = 'achievements_enabled';
  static const moderationAiAdvisory = 'moderation_ai_advisory';
  static const maintenanceBanner = 'maintenance_banner';

  /// In-app fallbacks — used before the first fetch and when offline. These
  /// MUST match the Console / template defaults so behaviour is identical
  /// either way.
  static const Map<String, Object> defaults = {
    aiSummary: true,
    aiChat: true,
    hybridSearch: true,
    requests: true,
    achievements: true,
    moderationAiAdvisory: true,
    maintenanceBanner: '',
  };

  /// Read a boolean flag. Falls back to the in-app default when Remote Config
  /// is unavailable (e.g. before init, or in widget tests with no Firebase) so
  /// gated widgets stay testable and the app never throws on a flag read.
  static bool isOn(String key) {
    try {
      return FirebaseRemoteConfig.instance.getBool(key);
    } catch (_) {
      return (defaults[key] as bool?) ?? false;
    }
  }

  /// Read a string flag (e.g. [maintenanceBanner]); same safe fallback.
  static String text(String key) {
    try {
      return FirebaseRemoteConfig.instance.getString(key);
    } catch (_) {
      return (defaults[key] as String?) ?? '';
    }
  }
}

/// Configures Remote Config: sets fetch settings + defaults and activates the
/// last fetched values. Call once during Firebase init. Never throws — flags
/// fall back to [AppFlags.defaults] if the network fetch fails.
Future<void> initRemoteConfig() async {
  final rc = FirebaseRemoteConfig.instance;
  try {
    await rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // Throttle live fetches in release; fetch freely in debug.
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(hours: 1),
      ),
    );
    await rc.setDefaults(AppFlags.defaults);
    await rc.fetchAndActivate();
  } catch (e) {
    // Offline / fetch failure: defaults are already set, so the app still works.
    debugPrint('Remote Config init failed, using defaults: $e');
  }
}
