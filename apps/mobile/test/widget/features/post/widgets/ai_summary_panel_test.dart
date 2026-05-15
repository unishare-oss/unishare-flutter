import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/ai_summary_panel.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.build(AppThemes.unishare),
  home: Scaffold(body: child),
);

void main() {
  group('AiSummaryPanel', () {
    testWidgets('null status — renders nothing (SizedBox.shrink)', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const AiSummaryPanel(status: null)));
      await tester.pump();

      expect(find.text('AI SUMMARY'), findsNothing);
    });

    testWidgets('pending — shows AI SUMMARY header', (tester) async {
      await tester.pumpWidget(
        _wrap(const AiSummaryPanel(status: SummaryStatus.pending)),
      );
      await tester.pump();

      expect(find.text('AI SUMMARY'), findsOneWidget);
    });

    testWidgets('done — shows header and summary content', (tester) async {
      const summary = 'Intro sentence.\n• Topic one\n• Topic two';
      await tester.pumpWidget(
        _wrap(
          const AiSummaryPanel(status: SummaryStatus.done, summary: summary),
        ),
      );
      await tester.pump();

      expect(find.text('AI SUMMARY'), findsOneWidget);
      expect(find.text('Intro sentence.'), findsOneWidget);
      expect(find.text('Topic one'), findsOneWidget);
    });

    testWidgets('flagged — shows AI SUMMARY header and unavailable chip', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const AiSummaryPanel(status: SummaryStatus.flagged)),
      );
      await tester.pump();

      expect(find.text('AI SUMMARY'), findsOneWidget);
      expect(find.text('Summary unavailable'), findsOneWidget);
    });

    testWidgets('error — shows AI SUMMARY header and unavailable chip', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const AiSummaryPanel(status: SummaryStatus.error)),
      );
      await tester.pump();

      expect(find.text('AI SUMMARY'), findsOneWidget);
      expect(find.text('Summary unavailable'), findsOneWidget);
    });

    testWidgets('unsupportedType — shows unsupported message', (tester) async {
      await tester.pumpWidget(
        _wrap(const AiSummaryPanel(status: SummaryStatus.unsupportedType)),
      );
      await tester.pump();

      expect(find.text('AI SUMMARY'), findsOneWidget);
      expect(
        find.text('Summary not supported for this file type'),
        findsOneWidget,
      );
    });
  });
}
