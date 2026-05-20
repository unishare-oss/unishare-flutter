import 'dart:io' show Platform;

/// Returns `'ios'` on iOS, `'android'` on Android.
///
/// Only imported on platforms that have dart:io (iOS, Android, macOS, Linux,
/// Windows).  Web uses the stub instead.
String get currentPlatformLabel => Platform.isIOS ? 'ios' : 'android';
