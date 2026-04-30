import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // Drain async font-loading side effects so they don't bleed into
  // the next test and cause spurious post-completion failures.
  Future<void> drainFonts(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }

  group('AppTheme.fromId', () {
    testWidgets('unishare is light', (tester) async {
      final theme = AppTheme.fromId('unishare');
      expect(theme.brightness, Brightness.light);
      await drainFonts(tester);
    });

    testWidgets('catppuccin-mocha is dark', (tester) async {
      final theme = AppTheme.fromId('catppuccin-mocha');
      expect(theme.brightness, Brightness.dark);
      await drainFonts(tester);
    });

    testWidgets('all themes include AppColors extension', (tester) async {
      for (final id in [
        'unishare',
        'catppuccin-mocha',
        'catppuccin-latte',
        'nord',
        'arctic',
        'tokyo-night',
        'dracula',
        'gruvbox-dark',
        'midnight-library',
        'parchment',
        'ocean-depth',
        'sakura',
      ]) {
        final theme = AppTheme.fromId(id);
        expect(
          theme.extension<AppColors>(),
          isNotNull,
          reason: '$id is missing AppColors extension',
        );
      }
      await drainFonts(tester);
    });

    testWidgets('unknown id falls back to unishare', (tester) async {
      final theme = AppTheme.fromId('does-not-exist');
      expect(theme.brightness, Brightness.light);
      expect(theme.extension<AppColors>()?.amber, const Color(0xFFD97706));
      await drainFonts(tester);
    });

    testWidgets('unishare amber token is amber color', (tester) async {
      final theme = AppTheme.fromId('unishare');
      final colors = theme.extension<AppColors>()!;
      expect(colors.amber, const Color(0xFFD97706));
      await drainFonts(tester);
    });

    testWidgets('scaffold background matches theme background', (tester) async {
      final theme = AppTheme.fromId('unishare');
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF7F3EE));
      await drainFonts(tester);
    });
  });
}
