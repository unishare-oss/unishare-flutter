import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/firebase/firebase_init.dart';
import 'core/storage/post_draft_box.dart';
import 'core/router/router.dart';
import 'shared/theme/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();
  await Hive.initFlutter();
  await initPostDraftBox();
  await Hive.openBox('settings');
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final theme = ref.watch(activeThemeProvider);
    return MaterialApp.router(
      title: 'Unishare',
      theme: theme,
      routerConfig: router,
    );
  }
}
