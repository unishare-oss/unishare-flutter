import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/attachment_carousel.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.build(AppThemes.unishare),
  home: Scaffold(body: child),
);

void main() {
  group('AttachmentCarousel', () {
    testWidgets('empty mediaUrls list renders SizedBox.shrink()', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const AttachmentCarousel(mediaUrls: [], mediaTypes: [])),
      );
      await tester.pump();

      // No ListView when there are no items.
      expect(find.byType(ListView), findsNothing);
      // Widget tree contains a SizedBox with zero size.
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final shrunk = sizedBoxes
          .where((b) => b.width == 0 && b.height == 0)
          .toList();
      // SizedBox.shrink() has width: 0 and height: 0.
      expect(shrunk, isNotEmpty);
    });

    testWidgets('image slot renders CachedNetworkImage', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AttachmentCarousel(
            mediaUrls: ['https://example.com/image.jpg'],
            mediaTypes: ['image'],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('video slot renders play_circle_fill icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AttachmentCarousel(
            mediaUrls: ['https://example.com/video.mp4'],
            mediaTypes: ['video'],
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
    });

    testWidgets(
      'PDF slot renders GestureDetector and "PDF" label text overlay',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const AttachmentCarousel(
              mediaUrls: ['https://example.com/doc.pdf'],
              mediaTypes: ['pdf'],
            ),
          ),
        );
        await tester.pump();

        // The PDF slot wraps content in a GestureDetector for tap-to-view.
        expect(find.byType(GestureDetector), findsWidgets);
        // The "PDF" label overlay is always rendered.
        expect(find.text('PDF'), findsOneWidget);
      },
    );

    testWidgets(
      'mismatched arrays (more urls than types) fall back to image slot',
      (tester) async {
        // 2 URLs but only 1 type → second slot falls back to "image".
        await tester.pumpWidget(
          _wrap(
            const AttachmentCarousel(
              mediaUrls: [
                'https://example.com/img1.jpg',
                'https://example.com/img2.jpg',
              ],
              mediaTypes: ['image'], // shorter than mediaUrls
            ),
          ),
        );
        await tester.pump();

        // Both slots should render as CachedNetworkImage (image fallback).
        expect(find.byType(CachedNetworkImage), findsNWidgets(2));
      },
    );
  });
}
