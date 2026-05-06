import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';
import 'package:unishare_mobile/features/post/domain/usecases/create_post.dart';
import 'package:unishare_mobile/features/post/domain/usecases/sync_draft_queue.dart';
import 'package:unishare_mobile/features/post/presentation/providers/draft_queue_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';
import 'package:unishare_mobile/features/post/presentation/screens/create_post_screen.dart';

// ---------------------------------------------------------------------------
// Stub repository — no Firebase or Hive calls
// ---------------------------------------------------------------------------

class _StubRepo implements PostRepository {
  @override
  Stream<List<Post>> watchFeed({int limit = 20}) => throw UnimplementedError();
  @override
  Future<void> saveDraft(PostDraft draft) async {}
  @override
  Future<void> removeDraft(String draftId) async {}
  @override
  Future<List<PostDraft>> loadDraftQueue() async => [];
  @override
  Future<void> publishDraft(
    PostDraft draft, {
    void Function(double)? onProgress,
    Map<String, Uint8List>? fileDataOverride,
  }) async {}
}

// Fake DraftQueueNotifier that never touches Hive.
class _FakeDraftQueueNotifier extends DraftQueueNotifier {
  @override
  List<PostDraft> build() => [];
}

// ---------------------------------------------------------------------------
// Helper: pump the screen with overridden providers
// ---------------------------------------------------------------------------

Widget _makeScreen() {
  return ProviderScope(
    overrides: [
      postRepositoryProvider.overrideWithValue(_StubRepo()),
      createPostUseCaseProvider.overrideWithValue(CreatePost(_StubRepo())),
      syncDraftQueueUseCaseProvider.overrideWithValue(
        SyncDraftQueue(_StubRepo()),
      ),
      // Override draftQueueProvider so DraftQueueIndicator never opens Hive.
      draftQueueProvider.overrideWith(() => _FakeDraftQueueNotifier()),
    ],
    child: const MaterialApp(home: CreatePostScreen()),
  );
}

void main() {
  group('CreatePostScreen wizard', () {
    testWidgets('renders step 1 heading and type cards', (tester) async {
      await tester.pumpWidget(_makeScreen());
      await tester.pump();
      expect(find.text('What are you sharing?'), findsOneWidget);
      expect(find.text('Lecture Note'), findsOneWidget);
      expect(find.text('Exercise'), findsOneWidget);
      expect(find.text('Past Exam'), findsOneWidget);
    });

    testWidgets('Next button is disabled on step 1 until a type is selected', (
      tester,
    ) async {
      await tester.pumpWidget(_makeScreen());
      await tester.pump();

      final nextButton = find.widgetWithText(FilledButton, 'Next');
      expect(nextButton, findsOneWidget);

      final button = tester.widget<FilledButton>(nextButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('tapping Lecture Note enables Next and advances to step 2', (
      tester,
    ) async {
      await tester.pumpWidget(_makeScreen());
      await tester.pump();

      await tester.tap(find.text('Lecture Note'));
      await tester.pump();

      final nextButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Next'),
      );
      expect(nextButton.onPressed, isNotNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();

      expect(find.text('Which course is this for?'), findsOneWidget);
    });

    testWidgets('Back on step 1 does not crash when no prior route', (
      tester,
    ) async {
      await tester.pumpWidget(_makeScreen());
      await tester.pump();

      final backBtn = find.widgetWithText(TextButton, 'Back');
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pump();
    });

    testWidgets(
      'step 2: Next is disabled until both year and course are selected',
      (tester) async {
        await tester.pumpWidget(_makeScreen());
        await tester.pump();

        await tester.tap(find.text('Lecture Note'));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Next'));
        await tester.pumpAndSettle();

        expect(find.text('Which course is this for?'), findsOneWidget);

        final nextButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Next'),
        );
        expect(nextButton.onPressed, isNull);
      },
    );

    testWidgets(
      'step 3: Next is disabled until title, description, and module are filled',
      (tester) async {
        await tester.pumpWidget(_makeScreen());
        await tester.pump();

        // Step 1
        await tester.tap(find.text('Lecture Note'));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Next'));
        await tester.pumpAndSettle();

        // Step 2 — select year
        await tester.tap(find.text('Select year'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Year 1').last);
        await tester.pumpAndSettle();

        // Step 2 — select course
        await tester.tap(find.text('Select course'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CSC101 Introduction to Computing').last);
        await tester.pumpAndSettle();

        var nextButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Next'),
        );
        expect(nextButton.onPressed, isNotNull);

        await tester.tap(find.widgetWithText(FilledButton, 'Next'));
        await tester.pumpAndSettle();

        expect(find.text('Add details'), findsOneWidget);

        nextButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Next'),
        );
        expect(nextButton.onPressed, isNull);
      },
    );

    testWidgets('step 4: Submit button is always enabled', (tester) async {
      await tester.pumpWidget(_makeScreen());
      await tester.pump();

      // Step 1
      await tester.tap(find.text('Lecture Note'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();

      // Step 2
      await tester.tap(find.text('Select year'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Year 1').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select course'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CSC101 Introduction to Computing').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();

      // Step 3 — fill required fields
      await tester.enterText(find.byType(TextField).at(0), 'My Title');
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(1), 'My description');
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(2), '3');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();

      expect(find.text('Upload files'), findsOneWidget);

      final submitButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Submit'),
      );
      expect(submitButton.onPressed, isNotNull);
    });

    testWidgets('Back navigates from step 2 to step 1', (tester) async {
      await tester.pumpWidget(_makeScreen());
      await tester.pump();

      await tester.tap(find.text('Lecture Note'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();

      expect(find.text('Which course is this for?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Back'));
      await tester.pumpAndSettle();

      expect(find.text('What are you sharing?'), findsOneWidget);
    });
  });
}
