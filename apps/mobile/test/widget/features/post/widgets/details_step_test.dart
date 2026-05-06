import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/details_step.dart';

Widget _wrap({
  PostingIdentity identity = PostingIdentity.named,
  List<String> tags = const [],
  void Function(PostingIdentity)? onIdentityChanged,
  void Function(List<String>)? onTagsChanged,
}) {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final moduleCtrl = TextEditingController();
  final urlCtrl = TextEditingController();

  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: DetailsStep(
          titleController: titleCtrl,
          descriptionController: descCtrl,
          moduleNumberController: moduleCtrl,
          externalUrlController: urlCtrl,
          postingIdentity: identity,
          semester: 1,
          tags: tags,
          onIdentityChanged: onIdentityChanged ?? (_) {},
          onSemesterChanged: (_) {},
          onTagsChanged: onTagsChanged ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  group('DetailsStep', () {
    testWidgets('renders heading and required field labels', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Add details'), findsOneWidget);
      // Field labels use RichText directly — check via plainText.
      bool hasLabel(String label) => tester
          .widgetList<RichText>(find.byType(RichText))
          .any((w) => w.text.toPlainText().contains(label));
      expect(hasLabel('TITLE'), isTrue);
      expect(hasLabel('DESCRIPTION'), isTrue);
      expect(hasLabel('MODULE NUMBER'), isTrue);
    });

    testWidgets('tapping anonymous radio updates identity', (tester) async {
      PostingIdentity? changed;
      await tester.pumpWidget(_wrap(onIdentityChanged: (v) => changed = v));

      await tester.tap(find.text('Post anonymously'));
      await tester.pump();

      expect(changed, PostingIdentity.anonymous);
    });

    testWidgets('anonymous option shows helper text', (tester) async {
      await tester.pumpWidget(_wrap(identity: PostingIdentity.anonymous));
      expect(
        find.textContaining('Moderators can still review'),
        findsOneWidget,
      );
    });

    testWidgets('tag input adds tag on submit and calls onTagsChanged', (
      tester,
    ) async {
      final tags = <String>[];
      await tester.pumpWidget(_wrap(onTagsChanged: tags.addAll));

      final tagField = find.byType(TextField).last;
      await tester.enterText(tagField, 'flutter');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(tags, contains('flutter'));
    });

    testWidgets('existing tags render as chips', (tester) async {
      await tester.pumpWidget(_wrap(tags: ['dart', 'flutter']));
      expect(find.text('#dart'), findsOneWidget);
      expect(find.text('#flutter'), findsOneWidget);
    });

    testWidgets('6th tag is rejected — chip count stays at 5', (tester) async {
      final tags = ['a', 'b', 'c', 'd', 'e'];
      final result = <String>[];

      await tester.pumpWidget(
        _wrap(
          tags: tags,
          onTagsChanged: (updated) => result
            ..clear()
            ..addAll(updated),
        ),
      );

      // Try to add a 6th tag via the text field.
      final tagField = find.byType(TextField).last;
      await tester.enterText(tagField, 'sixth');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // onTagsChanged should not have been called with a 6th entry.
      expect(result, isEmpty); // not called because _addTag guards against >5
    });
  });
}
