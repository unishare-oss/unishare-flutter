import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/domain/entities/ai_message.dart';
import 'package:unishare_mobile/features/post/presentation/providers/ask_ai_provider.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/ai_message_bubble.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/ask_ai_section.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

class _FakeAskAiNotifier extends AskAi {
  _FakeAskAiNotifier(this._initial);
  final List<AiMessage> _initial;

  @override
  AsyncValue<List<AiMessage>> build(String postId) => AsyncData(_initial);
}

Widget _wrap(Widget child, {List<AiMessage> messages = const []}) =>
    ProviderScope(
      overrides: [
        askAiProvider(
          'post-1',
        ).overrideWith(() => _FakeAskAiNotifier(messages)),
      ],
      child: MaterialApp(
        theme: AppTheme.build(AppThemes.unishare),
        home: Scaffold(body: child),
      ),
    );

const _section = AskAiSection(postId: 'post-1', summary: 'A document summary.');

void main() {
  group('AskAiSection', () {
    testWidgets('collapsed by default — shows ASK AI header, no message list', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_section));
      await tester.pump();

      expect(find.text('ASK AI'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('tap header — expands to show input and placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_section));
      await tester.pump();

      await tester.tap(find.text('ASK AI'));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Ask anything about this document…'), findsOneWidget);
    });

    testWidgets('tap header again — collapses', (tester) async {
      await tester.pumpWidget(_wrap(_section));
      await tester.pump();

      await tester.tap(find.text('ASK AI'));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);

      await tester.tap(find.text('ASK AI'));
      await tester.pump();
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('with messages — renders AiMessageBubble for each', (
      tester,
    ) async {
      const messages = [
        AiMessage(content: 'What is this?', isUser: true),
        AiMessage(content: 'It is a lecture note.', isUser: false),
      ];
      await tester.pumpWidget(_wrap(_section, messages: messages));
      await tester.pump();

      await tester.tap(find.text('ASK AI'));
      await tester.pump();

      expect(find.byType(AiMessageBubble), findsNWidgets(2));
      expect(find.text('What is this?'), findsOneWidget);
      expect(find.text('It is a lecture note.'), findsOneWidget);
    });

    testWidgets('pending bubble shows CircularProgressIndicator', (
      tester,
    ) async {
      const messages = [
        AiMessage(content: 'question', isUser: true),
        AiMessage(content: '', isUser: false, isPending: true),
      ];
      await tester.pumpWidget(_wrap(_section, messages: messages));
      await tester.pump();

      await tester.tap(find.text('ASK AI'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
