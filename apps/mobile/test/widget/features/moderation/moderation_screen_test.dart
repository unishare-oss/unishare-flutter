import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/moderation/domain/entities/moderation_verdict.dart';
import 'package:unishare_mobile/features/moderation/domain/entities/pending_post.dart';
import 'package:unishare_mobile/features/moderation/presentation/providers/moderation_action_provider.dart';
import 'package:unishare_mobile/features/moderation/presentation/providers/moderation_queue_provider.dart';
import 'package:unishare_mobile/features/moderation/presentation/screens/moderation_screen.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/attachment_carousel.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

final _now = DateTime(2026, 5, 20, 12);

final _fakePosts = [
  PendingPost(
    id: 'post1',
    title: 'LR Parsing Notes',
    description: 'Notes on LR parsing from CSC233.',
    authorId: 'uid1',
    authorName: 'Alice',
    tags: ['compiler'],
    postType: 'lectureNote',
    createdAt: _now.subtract(const Duration(hours: 2)),
    aiVerdict: ModerationVerdict(
      recommended: 'approve',
      confidence: 0.92,
      reason: 'Academic content, appropriate.',
      processedAt: _now.subtract(const Duration(hours: 1)),
    ),
  ),
];

final _fakePostsWithMedia = [
  PendingPost(
    id: 'post2',
    title: 'Lab 3 worksheet',
    description: 'Exercise sheet for lab 3.',
    authorId: 'uid2',
    authorName: 'Bob',
    tags: ['lab'],
    postType: 'exercise',
    createdAt: _now.subtract(const Duration(hours: 1)),
    mediaUrls: const ['https://cdn.example.com/posts/uid2/diagram.png'],
    mediaTypes: const ['image'],
  ),
];

final _fakeRejected = [
  PendingPost(
    id: 'post3',
    title: 'Spammy Notes',
    description: 'Buy cheap essays here.',
    authorId: 'uid3',
    authorName: 'Carol',
    tags: ['spam'],
    postType: 'lectureNote',
    createdAt: _now.subtract(const Duration(days: 2)),
    moderatedBy: 'mod1',
    moderatedAt: _now.subtract(const Duration(days: 1)),
    rejectionReason: 'Promotional spam, not academic content.',
  ),
];

/// Builds the screen with the given queue data. The rejected queue defaults
/// to empty so the (lazily built) Rejected tab never hits Firestore. Pass
/// [pendingError] to exercise the pending error branch.
Widget _subject({
  Stream<List<PendingPost>>? pending,
  Object? pendingError,
  Stream<List<PendingPost>>? rejected,
}) {
  final pendingOverride = pendingError != null
      ? moderationQueueProvider.overrideWithValue(
          AsyncError(pendingError, StackTrace.empty),
        )
      : moderationQueueProvider.overrideWith(
          (ref) => pending ?? const Stream.empty(),
        );

  // Inferred List<Override> — avoids naming the (unexported) Override type.
  final overrides = [
    pendingOverride,
    moderationRejectedQueueProvider.overrideWith(
      (ref) => rejected ?? Stream.value(<PendingPost>[]),
    ),
    moderationActionProvider.overrideWith(ModerationAction.new),
  ];

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: const ModerationScreen(),
    ),
  );
}

void main() {
  group('ModerationScreen — Pending tab', () {
    testWidgets('shows loading indicator while queue is loading', (
      tester,
    ) async {
      await tester.pumpWidget(_subject(pending: const Stream.empty()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no pending posts', (tester) async {
      await tester.pumpWidget(_subject(pending: Stream.value([])));
      await tester.pump();
      expect(find.text('No pending posts'), findsOneWidget);
    });

    testWidgets('renders pending post cards with AI verdict', (tester) async {
      await tester.pumpWidget(_subject(pending: Stream.value(_fakePosts)));
      await tester.pump();
      expect(find.text('LR Parsing Notes'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('APPROVE'), findsOneWidget);
      // lectureNote renders the canonical "NOTE" label, not "LECTURENOTE".
      expect(find.text('NOTE'), findsOneWidget);
      expect(find.text('LECTURENOTE'), findsNothing);
      // No media on this post → no carousel.
      expect(find.byType(AttachmentCarousel), findsNothing);
    });

    testWidgets('renders attachment carousel when post has media', (
      tester,
    ) async {
      await tester.pumpWidget(
        _subject(pending: Stream.value(_fakePostsWithMedia)),
      );
      await tester.pump();
      expect(find.byType(AttachmentCarousel), findsOneWidget);
      expect(find.text('EXERCISE'), findsOneWidget);
    });

    testWidgets('shows error state on queue error', (tester) async {
      await tester.pumpWidget(
        _subject(pendingError: Exception('Firestore error')),
      );
      expect(find.byKey(const Key('moderation-error')), findsOneWidget);
    });
  });

  group('ModerationScreen — Rejected tab', () {
    testWidgets('lists rejected posts with reason and restore action', (
      tester,
    ) async {
      await tester.pumpWidget(
        _subject(
          pending: Stream.value([]),
          rejected: Stream.value(_fakeRejected),
        ),
      );
      await tester.pump();

      // Switch to the Rejected tab.
      await tester.tap(find.text('Rejected'));
      await tester.pumpAndSettle();

      expect(find.text('Spammy Notes'), findsOneWidget);
      expect(
        find.text('Promotional spam, not academic content.'),
        findsOneWidget,
      );
      expect(find.text('Restore to queue'), findsOneWidget);
      // No pending-only affordances on a rejected card.
      expect(find.text('Approve'), findsNothing);
    });

    testWidgets('shows empty state when no rejected posts', (tester) async {
      await tester.pumpWidget(_subject(pending: Stream.value([])));
      await tester.pump();

      await tester.tap(find.text('Rejected'));
      await tester.pumpAndSettle();

      expect(find.text('No rejected posts'), findsOneWidget);
    });
  });
}
