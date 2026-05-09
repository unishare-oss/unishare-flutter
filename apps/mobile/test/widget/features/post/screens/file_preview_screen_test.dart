// Tests for FilePreviewScreen — validates routing to the correct sub-viewer
// and that the UnsupportedViewer fallback works.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/presentation/screens/file_preview_screen.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

// Minimal theme: provides AppColors extension and colorScheme.error without
// triggering GoogleFonts network/asset lookups (which fail in test hosts).
ThemeData _testTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD97706)).copyWith(
    error: const Color(0xFFDC2626),
    surface: const Color(0xFFF7F3EE),
    onSurface: const Color(0xFF1C1917),
  ),
  scaffoldBackgroundColor: const Color(0xFFF7F3EE),
  dividerColor: const Color(0xFFE2DAD0),
  extensions: const [
    AppColors(
      muted: Color(0xFFF7F3EE),
      mutedForeground: Color(0xFF6B6560),
      textSecondary: Color(0xFF6B6560),
      textMuted: Color(0xFF8A837E),
      amber: Color(0xFFD97706),
      amberHover: Color(0xFFB45309),
      amberSubtle: Color(0xFFFEF3C7),
      success: Color(0xFF16A34A),
      info: Color(0xFF0369A1),
      surfaceDark: Color(0xFF1C1917),
      cardDark: Color(0xFFF0EBE4),
    ),
  ],
);

Widget _wrap(Widget child) => MaterialApp(theme: _testTheme(), home: child);

/// Suppress framework errors caused by missing platform channels (pdfrx,
/// video_player, connectivity_plus) so only genuine test failures surface.
void Function(FlutterErrorDetails)? _originalOnError;

void _suppressPlatformErrors() {
  _originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final msg = details.exception.toString();
    if (msg.contains('MissingPluginException') ||
        msg.contains('PlatformException')) {
      return; // swallow expected plugin errors in unit-test host
    }
    _originalOnError?.call(details);
  };
}

void _restoreErrorHandler() => FlutterError.onError = _originalOnError;

void main() {
  group('FilePreviewScreen routing', () {
    setUp(_suppressPlatformErrors);
    tearDown(_restoreErrorHandler);

    // Mock connectivity_plus and path_provider channels used by _VideoViewer
    // and _PdfViewer so pumping doesn't throw MissingPluginException.
    setUpAll(() {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async {
          // Both getTemporaryDirectory (video cache) and
          // getApplicationSupportDirectory (flutter_cache_manager) must return
          // a valid path so CachedNetworkImage does not throw.
          if (call.method == 'getTemporaryDirectory' ||
              call.method == 'getApplicationSupportDirectory') {
            return '/tmp';
          }
          return null;
        },
      );

      messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (call) async {
          if (call.method == 'check') return ['wifi'];
          return null;
        },
      );
    });

    tearDownAll(() {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        null,
      );
    });

    testWidgets('shows _UnsupportedViewer for unknown type', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FilePreviewScreen(
            url: 'https://example.com/file.xyz',
            type: 'unknown',
            filename: 'file.xyz',
          ),
        ),
      );

      // The unsupported viewer displays the file name in the AppBar and the
      // "Preview not available" message in the body.
      expect(find.text('file.xyz'), findsOneWidget);
      expect(
        find.text('Preview not available for this file type'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });

    testWidgets('shows _UnsupportedViewer for empty type', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FilePreviewScreen(
            url: 'https://example.com/doc',
            type: '',
            filename: 'doc',
          ),
        ),
      );

      expect(
        find.text('Preview not available for this file type'),
        findsOneWidget,
      );
    });

    testWidgets('routes image type to _ImageViewer with InteractiveViewer', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const FilePreviewScreen(
            url: 'https://example.com/photo.jpg',
            type: 'image',
            filename: 'photo.jpg',
          ),
        ),
      );
      // One pump — InteractiveViewer is in tree immediately (no async).
      await tester.pump();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('photo.jpg'), findsOneWidget);
      // Must NOT show the unsupported-viewer message.
      expect(
        find.text('Preview not available for this file type'),
        findsNothing,
      );
    });

    testWidgets('routes pdf type to _PdfViewer showing filename in AppBar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const FilePreviewScreen(
            url: 'https://example.com/doc.pdf',
            type: 'pdf',
            filename: 'doc.pdf',
          ),
        ),
      );
      await tester.pump();

      // PDF branch was taken — AppBar has filename, no unsupported message.
      expect(find.text('doc.pdf'), findsOneWidget);
      expect(
        find.text('Preview not available for this file type'),
        findsNothing,
      );
      // Spec: loading spinner shown while _isLoading is true (before isReady).
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('routes video type to _VideoViewer showing loading spinner', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const FilePreviewScreen(
            url: 'https://example.com/lecture.mp4',
            type: 'video',
            filename: 'lecture.mp4',
          ),
        ),
      );
      // Initial frame — _VideoDownloadState.loading is set synchronously in
      // initState before _init() completes any async work.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('lecture.mp4'), findsOneWidget);
      expect(
        find.text('Preview not available for this file type'),
        findsNothing,
      );
    });
  });

  group('videoCachePath', () {
    // Mock path_provider so tests don't need a real device filesystem.
    setUpAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async {
              if (call.method == 'getTemporaryDirectory') return '/tmp';
              return null;
            },
          );
    });

    tearDownAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
    });

    test('strips query parameters from URL', () async {
      final path = await videoCachePath(
        'https://storage.example.com/videos/lecture.mp4?token=abc123&exp=999',
      );
      expect(path, endsWith('/unishare_video/lecture.mp4'));
      expect(path, isNot(contains('?')));
    });

    test('returns path under unishare_video subdirectory', () async {
      final path = await videoCachePath(
        'https://storage.example.com/videos/clip.mp4',
      );
      expect(path, contains('/unishare_video/'));
      expect(path, endsWith('clip.mp4'));
    });
  });
}
