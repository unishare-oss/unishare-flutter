/// Stub used on web (and any platform without dart:io).
///
/// Returns a safe fallback so the call site in [FcmService] compiles and
/// runs on web without referencing dart:io.
String get currentPlatformLabel => 'unknown';
