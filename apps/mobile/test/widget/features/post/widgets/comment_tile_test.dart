import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/domain/entities/comment.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/comment_tile.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

void main() {
  group('CommentTile', () {
    testWidgets('renders author name and body', (tester) async {
      final comment = Comment(
        id: 'c-1',
        authorId: 'author-1',
        authorName: 'Alice',
        authorAvatar: '',
        body: 'Great post!',
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: Scaffold(body: CommentTile(comment: comment)),
        ),
      );
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Great post!'), findsOneWidget);
    });

    testWidgets('renders formatted timestamp (minutes ago)', (tester) async {
      final comment = Comment(
        id: 'c-1',
        authorId: 'author-1',
        authorName: 'Bob',
        authorAvatar: '',
        body: 'Nice!',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: Scaffold(body: CommentTile(comment: comment)),
        ),
      );
      await tester.pump();

      // The relative-time formatter produces "5m ago".
      expect(find.text('5m ago'), findsOneWidget);
    });

    testWidgets('shows initials avatar when authorAvatar URL is empty', (
      tester,
    ) async {
      final comment = Comment(
        id: 'c-1',
        authorId: 'author-1',
        authorName: 'Alice',
        authorAvatar: '', // empty → initials fallback
        body: 'Hello',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: Scaffold(body: CommentTile(comment: comment)),
        ),
      );
      await tester.pump();

      // Initials avatar displays the first letter of the name.
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('initials fallback shows "?" when author name is empty', (
      tester,
    ) async {
      final comment = Comment(
        id: 'c-1',
        authorId: 'author-1',
        authorName: '',
        authorAvatar: '',
        body: 'Anonymous',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: Scaffold(body: CommentTile(comment: comment)),
        ),
      );
      await tester.pump();

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('shows Reply button when onReply callback is provided', (
      tester,
    ) async {
      final comment = Comment(
        id: 'c-1',
        authorId: 'author-1',
        authorName: 'Alice',
        authorAvatar: '',
        body: 'Hello',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: Scaffold(
            body: CommentTile(comment: comment, onReply: () {}),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Reply'), findsOneWidget);
    });

    testWidgets('hides Reply button when onReply is null', (tester) async {
      final comment = Comment(
        id: 'c-1',
        authorId: 'author-1',
        authorName: 'Alice',
        authorAvatar: '',
        body: 'Hello',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: Scaffold(body: CommentTile(comment: comment)),
        ),
      );
      await tester.pump();

      expect(find.text('Reply'), findsNothing);
    });

    testWidgets('tapping Reply invokes onReply callback', (tester) async {
      var called = false;
      final comment = Comment(
        id: 'c-1',
        authorId: 'author-1',
        authorName: 'Alice',
        authorAvatar: '',
        body: 'Hello',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: Scaffold(
            body: CommentTile(comment: comment, onReply: () => called = true),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Reply'));
      expect(called, isTrue);
    });

    testWidgets('renders replies nested under parent comment', (tester) async {
      final parent = Comment(
        id: 'c-1',
        authorId: 'author-1',
        authorName: 'Alice',
        authorAvatar: '',
        body: 'Parent comment',
        createdAt: DateTime.now(),
      );
      final reply = Comment(
        id: 'c-2',
        authorId: 'author-2',
        authorName: 'Bob',
        authorAvatar: '',
        body: 'A reply',
        createdAt: DateTime.now(),
        parentId: 'c-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommentTile(
                comment: parent,
                replies: [reply],
                onReply: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Parent comment'), findsOneWidget);
      expect(find.text('A reply'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });
  });
}
