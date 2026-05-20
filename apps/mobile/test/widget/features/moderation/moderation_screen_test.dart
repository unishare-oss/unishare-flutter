import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/moderation/domain/entities/moderation_verdict.dart';
import 'package:unishare_mobile/features/moderation/domain/entities/pending_post.dart';
import 'package:unishare_mobile/features/moderation/presentation/providers/moderation_action_provider.dart';
import 'package:unishare_mobile/features/moderation/presentation/providers/moderation_queue_provider.dart';
import 'package:unishare_mobile/features/moderation/presentation/screens/moderation_screen.dart';

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
          child: const MaterialApp(home: ModerationScreen()),
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
          child: const MaterialApp(home: ModerationScreen()),
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
          child: const MaterialApp(home: ModerationScreen()),
        ),
      );
      await tester.pump();
      expect(find.text('LR Parsing Notes'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('APPROVE'), findsOneWidget);
    });

    testWidgets('shows error state on queue error', (tester) async {
      // sync: true delivers addError() synchronously to Riverpod's listener,
      // bypassing the Dart event-queue deferral that breaks pump() timing in
      // Flutter's test zone.
      final controller = StreamController<List<PendingPost>>(sync: true);
      addTearDown(controller.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            moderationQueueProvider.overrideWith((ref) => controller.stream),
          ],
          child: const MaterialApp(home: ModerationScreen()),
        ),
      );

      controller.addError(Exception('Firestore error'));
      await tester
          .pump(); // Riverpod receives error → AsyncError, rebuild queued
      await tester.pump(); // Widget rebuilds, error text rendered
      expect(find.textContaining('Error'), findsOneWidget);
    });
  });
}
