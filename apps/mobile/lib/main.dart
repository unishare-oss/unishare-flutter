import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:unishare_mobile/core/firebase/fcm_service.dart';
import 'package:unishare_mobile/core/firebase/firebase_init.dart';
import 'package:unishare_mobile/core/logging/app_logger.dart';
import 'package:unishare_mobile/core/router/router.dart';
import 'package:unishare_mobile/core/storage/post_draft_box.dart';
import 'package:unishare_mobile/core/storage/saved_post_box.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:unishare_mobile/features/notifications/presentation/providers/notification_repository_provider.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/saved_post_repository_provider.dart';
import 'package:unishare_mobile/shared/theme/providers/font_size_provider.dart';
import 'package:unishare_mobile/shared/theme/providers/theme_provider.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await pdfrxFlutterInitialize(dismissPdfiumWasmWarnings: true);
  await initFirebase();
  await Hive.initFlutter();
  await initPostDraftBox();
  await initSavedPostBox();
  await Hive.openBox('settings');
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  StreamSubscription<FcmTapEvent>? _tapSub;

  @override
  void initState() {
    super.initState();
    // Subscribe to FCM deep-link taps once; the stream is broadcast so we
    // don't miss events that fire before the first build.
    _tapSub = FcmService.instance.onMessageTapped.listen(_handleTap);
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    super.dispose();
  }

  void _handleTap(FcmTapEvent event) {
    // Derive the GoRouter path from the payload fields defined in SPEC-0001.
    final String path;
    switch (event.targetType) {
      case 'post':
        path = '/posts/${event.targetId}';
      case 'request':
        path = '/more/requests/${event.targetId}';
      default:
        AppLogger.info(
          'FCM tap: unknown targetType "${event.targetType}" — ignoring',
        );
        return;
    }

    // Use the router's navigator key so we can push without a BuildContext.
    final router = ref.read(routerProvider);
    router.push(path);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(mergeGuestSavesOnLoginProvider);

    // Auth state listener: register FCM on sign-in, remove token on sign-out.
    ref.listen(authStateProvider, (prev, next) {
      final prevUser = prev?.value;
      final nextUser = next.value;

      if (nextUser != null && prevUser == null) {
        // ── Sign-in ──────────────────────────────────────────────────────────
        FcmService.instance.init(
          userId: nextUser.id,
          onTokenRegistered: (token, platform) => ref
              .read(notificationRepositoryProvider)
              .registerFcmToken(nextUser.id, token, platform),
        );
      } else if (nextUser == null && prevUser != null) {
        // ── Sign-out ─────────────────────────────────────────────────────────
        // Cancel FCM subscriptions first so token-refresh can't race with the
        // Firestore delete below.
        FcmService.instance.dispose();

        // Remove the token doc from Firestore BEFORE auth clears so the write
        // is still authorised under prevUser's UID.
        FcmService.instance.removeToken(
          userId: prevUser.id,
          onTokenRemoved: (token) => ref
              .read(notificationRepositoryProvider)
              .removeFcmToken(prevUser.id, token),
        );
      }
    });

    final router = ref.watch(routerProvider);
    final theme = ref.watch(activeThemeProvider);
    final fontStep = ref.watch(fontSizeProvider);
    final textScale = fontSizeScales[fontStep];
    return MaterialApp.router(
      title: 'Unishare',
      theme: theme,
      // Cross-fade ThemeData over 240ms so a theme switch reads as a
      // smooth transition instead of a single-frame layout snap.
      themeAnimationDuration: const Duration(milliseconds: 240),
      themeAnimationCurve: Curves.easeOutCubic,
      routerConfig: router,
      // Apply the app's font-size preference *on top of* the existing
      // MediaQuery (which carries the user's platform/accessibility text
      // scale + RTL, viewInsets, etc.). We multiply the platform scaler
      // by the app preference instead of replacing it, so a user who has
      // both OS accessibility scaling AND an in-app "Large" preference
      // gets the compound effect they expect.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        // `scale(1.0)` extracts the platform's linear multiplier without
        // assuming the scaler is linear-by-construction.
        final platformFactor = mq.textScaler.scale(1.0);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(platformFactor * textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
