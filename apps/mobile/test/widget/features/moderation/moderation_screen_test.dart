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

void main() {
  group('ModerationScreen', () {
    testWidgets('shows loading indicator while queue is loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            moderationQueueProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: MaterialApp(
            theme: AppTheme.build(AppThemes.unishare),
            home: const ModerationScreen(),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no pending posts', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            moderationQueueProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.build(AppThemes.unishare),
            home: const ModerationScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('No pending posts'), findsOneWidget);
    });

    testWidgets('renders pending post cards with AI verdict', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            moderationQueueProvider.overrideWith(
              (ref) => Stream.value(_fakePosts),
            ),
            moderationActionProvider.overrideWith(ModerationAction.new),
          ],
          child: MaterialApp(
            theme: AppTheme.build(AppThemes.unishare),
            home: const ModerationScreen(),
          ),
        ),
      );
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
        ProviderScope(
          overrides: [
            moderationQueueProvider.overrideWith(
              (ref) => Stream.value(_fakePostsWithMedia),
            ),
            moderationActionProvider.overrideWith(ModerationAction.new),
          ],
          child: MaterialApp(
            theme: AppTheme.build(AppThemes.unishare),
            home: const ModerationScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AttachmentCarousel), findsOneWidget);
      expect(find.text('EXERCISE'), findsOneWidget);
    });

    testWidgets('shows error state on queue error', (tester) async {
      // overrideWithValue(AsyncError) injects the error synchronously —
      // no stream subscription or async pipeline involved. The widget renders
      // the error branch in the first frame after pumpWidget.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            moderationQueueProvider.overrideWithValue(
              AsyncError(Exception('Firestore error'), StackTrace.empty),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.build(AppThemes.unishare),
            home: const ModerationScreen(),
          ),
        ),
      );
      expect(find.byKey(const Key('moderation-error')), findsOneWidget);
    });
  });
}
