import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:unishare_mobile/features/post/data/datasources/course_firestore_datasource.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';
import 'package:unishare_mobile/features/post/domain/usecases/create_post.dart';
import 'package:unishare_mobile/features/post/domain/usecases/sync_draft_queue.dart';
import 'package:unishare_mobile/features/post/presentation/providers/course_reference_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/draft_queue_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';
import 'package:unishare_mobile/features/post/presentation/screens/create_post_screen.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

// ---------------------------------------------------------------------------
// Stubs
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
  Stream<Post> watchPost(String postId) => throw UnimplementedError();
  @override
  Stream<List<Post>> watchPostsByAuthor(String authorId, {int limit = 50}) =>
      throw UnimplementedError();
  @override
  Future<int> countPostsByAuthor(String authorId) async => 0;
  @override
  Future<void> incrementViewCount(String postId) async {}
  @override
  Future<void> publishDraft(
    PostDraft draft, {
    void Function(double)? onProgress,
    void Function(int, double)? onFileProgress,
    void Function(PostDraft)? onDraftUpdated,
    Map<String, Uint8List>? fileDataOverride,
    CancellationToken? cancellationToken,
  }) async {}

  @override
  Future<void> deletePost(String postId) => throw UnimplementedError();

  @override
  Future<void> updatePost({
    required String postId,
    required String title,
    required String description,
    required List<String> tags,
    String? externalUrl,
    required String moduleNumber,
    required bool descriptionChanged,
    required SummaryStatus? currentSummaryStatus,
  }) => throw UnimplementedError();
}

class _FakeDraftQueueNotifier extends DraftQueueNotifier {
  @override
  List<PostDraft> build() => [];
}

class _FakeCourseDatasource implements CourseFirestoreDatasource {
  @override
  Future<List<({String id, String name})>> getDepartments(
    String universityId,
  ) async => [(id: 'dept-cs', name: 'Computer Science')];

  @override
  Future<List<({String id, String name})>> getCourses(
    String deptId,
    int year,
  ) async => [(id: 'csc101', name: 'CSC101 Introduction to Computing')];
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _makeScreen() {
  return ProviderScope(
    overrides: [
      postRepositoryProvider.overrideWithValue(_StubRepo()),
      createPostUseCaseProvider.overrideWithValue(CreatePost(_StubRepo())),
      syncDraftQueueUseCaseProvider.overrideWithValue(
        SyncDraftQueue(_StubRepo()),
      ),
      draftQueueProvider.overrideWith(() => _FakeDraftQueueNotifier()),
      courseFirestoreDatasourceProvider.overrideWithValue(
        _FakeCourseDatasource(),
      ),
      currentUserProvider.overrideWith(
        (_) async => AppUser(
          id: 'user-1',
          name: 'Test User',
          email: 'test@test.com',
          universityId: 'uni-1',
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: const CreatePostScreen(),
    ),
  );
}

/// Navigate to step 2 then select department + year + course.
Future<void> _completeStep2(WidgetTester tester) async {
  await tester.tap(find.text('Select department'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Computer Science').last);
  await tester.pumpAndSettle();

  await tester.tap(find.text('Select year'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Year 1').last);
  await tester.pumpAndSettle();

  await tester.tap(find.text('Select course'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('CSC101 Introduction to Computing').last);
  await tester.pumpAndSettle();
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
      'step 2: Next is disabled until department, year, and course are selected',
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

        // Step 2
        await _completeStep2(tester);

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
      await _completeStep2(tester);
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
