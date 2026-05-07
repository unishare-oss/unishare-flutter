// Tests for FilePreviewScreen — validates routing to the correct sub-viewer
// and that the UnsupportedViewer fallback works.
//
// _ImageViewer, _PdfViewer, and _VideoViewer are NOT covered here because they
// depend on external network calls, platform plugins (pdfrx, chewie,
// video_player), and the device filesystem. Those require integration tests or
// golden tests with full platform backing.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/presentation/screens/file_preview_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  group('FilePreviewScreen routing', () {
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
