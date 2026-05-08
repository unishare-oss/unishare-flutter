import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/presentation/providers/create_post_provider.dart';
import 'package:unishare_mobile/features/post/presentation/screens/upload_progress_screen.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

// ---------------------------------------------------------------------------
// Stub notifiers
// ---------------------------------------------------------------------------

class _UploadingNotifier extends CreatePostNotifier {
  @override
  CreatePostState build() => CreatePostUploading(
    files: [
      const FileUploadProgress(
        filename: 'notes.pdf',
        phase: FileUploadPhase.done,
        progress: 1.0,
      ),
      const FileUploadProgress(
        filename: 'diagram.png',
        phase: FileUploadPhase.uploading,
        progress: 0.34,
      ),
      const FileUploadProgress(
        filename: 'exam.pdf',
        phase: FileUploadPhase.queued,
      ),
    ],
    overallProgress: 0.48,
  );

  @override
  Future<void> cancel() async {}
}

class _PublishingNotifier extends CreatePostNotifier {
  @override
  CreatePostState build() => CreatePostPublishing(
    files: const [
      FileUploadProgress(
        filename: 'notes.pdf',
        phase: FileUploadPhase.done,
        progress: 1.0,
      ),
      FileUploadProgress(
        filename: 'diagram.png',
        phase: FileUploadPhase.done,
        progress: 1.0,
      ),
    ],
  );

  @override
  Future<void> cancel() async {}
}

class _ErrorNotifier extends CreatePostNotifier {
  @override
  CreatePostState build() => CreatePostError(
    message: 'Network error',
    draft: PostDraft(
      id: 'test',
      postType: PostType.lectureNote,
      year: 1,
      courseId: 'csc101',
      departmentId: 'dept-cs',
      title: 'T',
      description: 'D',
      postingIdentity: PostingIdentity.named,
      semester: 1,
      moduleNumber: '1',
      localMediaPaths: [],
      uploadedUrls: {},
      createdAt: DateTime(2026),
    ),
    overallProgress: 0.48,
  );

  @override
  Future<void> cancel() async {}
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _makeScreen(CreatePostNotifier notifier) => ProviderScope(
  overrides: [createPostProvider.overrideWith(() => notifier)],
  child: MaterialApp(
    theme: AppTheme.build(AppThemes.unishare),
    home: const UploadProgressScreen(),
  ),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('UploadProgressScreen', () {
    testWidgets('shows percentage and all three file rows when uploading', (
      tester,
    ) async {
      await tester.pumpWidget(_makeScreen(_UploadingNotifier()));
      await tester.pump();

      expect(find.text('48%'), findsOneWidget);
      expect(find.text('notes.pdf'), findsOneWidget);
      expect(find.text('diagram.png'), findsOneWidget);
      expect(find.text('exam.pdf'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('34%'), findsOneWidget);
      expect(find.text('Queued'), findsOneWidget);
    });

    testWidgets(
      'shows Publishing text and Done file rows when in publishing state',
      (tester) async {
        await tester.pumpWidget(_makeScreen(_PublishingNotifier()));
        await tester.pump();

        expect(find.text('Publishing…'), findsOneWidget);
        expect(find.text('Finishing up…'), findsOneWidget);
        expect(find.text('notes.pdf'), findsOneWidget);
        expect(find.text('diagram.png'), findsOneWidget);
        expect(find.text('Done'), findsNWidgets(2));
      },
    );

    testWidgets('Cancel button is disabled in publishing state', (
      tester,
    ) async {
      await tester.pumpWidget(_makeScreen(_PublishingNotifier()));
      await tester.pump();

      final cancelBtn = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cancel'),
      );
      expect(cancelBtn.onPressed, isNull);
    });

    testWidgets('shows error message and Retry button on error state', (
      tester,
    ) async {
      await tester.pumpWidget(_makeScreen(_ErrorNotifier()));
      await tester.pump();

      expect(find.text('Upload failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Cancel button is present and tappable when uploading', (
      tester,
    ) async {
      await tester.pumpWidget(_makeScreen(_UploadingNotifier()));
      await tester.pump();

      final cancelBtn = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cancel'),
      );
      expect(cancelBtn.onPressed, isNotNull);
    });
  });
}
