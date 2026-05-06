import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/type_step.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('TypeStep', () {
    testWidgets('renders all three cards', (tester) async {
      await tester.pumpWidget(
        _wrap(TypeStep(selected: null, onSelect: (_) {})),
      );
      expect(find.text('Lecture Note'), findsOneWidget);
      expect(find.text('Past Exam'), findsOneWidget);
      expect(find.text('Exercise'), findsOneWidget);
    });

    testWidgets('tapping Lecture Note calls onSelect with lectureNote', (
      tester,
    ) async {
      PostType? selected;
      await tester.pumpWidget(
        _wrap(TypeStep(selected: null, onSelect: (t) => selected = t)),
      );
      await tester.tap(find.text('Lecture Note'));
      await tester.pump();
      expect(selected, PostType.lectureNote);
    });

    testWidgets('tapping Assignment calls onSelect with assignment', (
      tester,
    ) async {
      PostType? selected;
      await tester.pumpWidget(
        _wrap(TypeStep(selected: null, onSelect: (t) => selected = t)),
      );
      await tester.tap(find.text('Exercise'));
      await tester.pump();
      expect(selected, PostType.exercise);
    });

    testWidgets('Past Exam card has Unavailable label and is not tappable', (
      tester,
    ) async {
      PostType? selected;
      await tester.pumpWidget(
        _wrap(TypeStep(selected: null, onSelect: (t) => selected = t)),
      );
      await tester.tap(find.text('Past Exam'));
      await tester.pump();
      // Past Exam is wrapped in Opacity, not a GestureDetector — no selection.
      expect(selected, isNull);
      expect(find.text('Unavailable'), findsOneWidget);
    });

    testWidgets('selected card shows checkmark icon', (tester) async {
      await tester.pumpWidget(
        _wrap(TypeStep(selected: PostType.lectureNote, onSelect: (_) {})),
      );
      // Check icon should be visible in the selected card.
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
