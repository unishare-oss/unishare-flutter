import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/domain/entities/ai_message.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/ai_message_bubble.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.build(AppThemes.unishare),
  home: Scaffold(body: child),
);

void main() {
  group('AiMessageBubble', () {
    testWidgets('user message — right-aligned, no warning icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AiMessageBubble(
            message: const AiMessage(content: 'Hello AI', isUser: true),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Hello AI'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets(
      'pending message — shows CircularProgressIndicator, left-aligned',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            AiMessageBubble(
              message: const AiMessage(
                content: '',
                isUser: false,
                isPending: true,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        final align = tester.widget<Align>(find.byType(Align).first);
        expect(align.alignment, Alignment.centerLeft);
      },
    );

    testWidgets('off-topic message — shows warning icon and italic text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AiMessageBubble(
            message: const AiMessage(
              content: 'Off topic reply',
              isUser: false,
              isOffTopic: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Off topic reply'), findsOneWidget);
      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerLeft);
    });

    testWidgets('default AI reply — left-aligned, no warning icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AiMessageBubble(
            message: const AiMessage(
              content: 'Here is the answer',
              isUser: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Here is the answer'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerLeft);
    });
  });
}
