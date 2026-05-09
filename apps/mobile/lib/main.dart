import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:unishare_mobile/core/firebase/firebase_init.dart';
import 'package:unishare_mobile/core/storage/post_draft_box.dart';
import 'package:unishare_mobile/core/storage/saved_post_box.dart';
import 'package:unishare_mobile/core/router/router.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/saved_post_repository_provider.dart';
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

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(mergeGuestSavesOnLoginProvider);
    final router = ref.watch(routerProvider);
    final theme = ref.watch(activeThemeProvider);
    return MaterialApp.router(
      title: 'Unishare',
      theme: theme,
      routerConfig: router,
    );
  }
}
