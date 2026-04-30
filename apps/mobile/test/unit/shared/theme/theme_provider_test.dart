import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:unishare_mobile/shared/theme/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('ThemeNotifier', () {
    test('initial state defaults to unishare when box is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(themeProvider), 'unishare');
    });

    test('initial state reads persisted value from Hive', () async {
      await Hive.box('settings').put('selected_theme', 'nord');
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(themeProvider), 'nord');
    });

    test('setTheme updates provider state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(themeProvider.notifier).setTheme('dracula');
      expect(container.read(themeProvider), 'dracula');
    });

    test('setTheme persists to Hive', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(themeProvider.notifier).setTheme('tokyo-night');
      expect(Hive.box('settings').get('selected_theme'), 'tokyo-night');
    });

    test('setTheme ignores unknown id', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(themeProvider.notifier).setTheme('not-a-real-theme');
      expect(container.read(themeProvider), 'unishare');
      expect(Hive.box('settings').get('selected_theme'), isNull);
    });
  });

  group('activeThemeProvider', () {
    test('returns ThemeData for selected theme', () async {
      late Brightness brightness;
      // google_fonts fires async font-load errors in the test zone when font
      // assets are not bundled. Wrap in runZonedGuarded so those errors are
      // discarded without failing the test.
      await runZonedGuarded(
        () async {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          brightness = container.read(activeThemeProvider).brightness;
          // Pump the microtask queue so the async font error fires inside this
          // guarded zone rather than leaking into the test zone.
          await Future<void>.delayed(Duration.zero);
        },
        (error, _) {
          // Swallow google_fonts font-not-found errors only.
          if (!error.toString().contains('google_fonts') &&
              !error.toString().contains('allowRuntimeFetching') &&
              !error.toString().contains('was not found in the application')) {
            fail('Unexpected error in activeThemeProvider test: $error');
          }
        },
      );
      expect(brightness, Brightness.light); // unishare default is light
    });
  });
}
