import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/router/router.dart';
import 'shared/theme/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
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
      // Single-slot theming: all themes (light and dark) live in the `theme` param.
      // ThemeMode.light forces MaterialApp to always use `theme`. Material 3 widgets
      // use colorScheme.brightness directly, so dark themes render correctly.
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
