import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/post_feed/presentation/screens/feed_screen.dart';
import 'package:unishare_mobile/features/post_feed/presentation/widgets/feed_empty_state_widget.dart';
import 'package:unishare_mobile/features/post_feed/presentation/widgets/filter_picker_widget.dart';
import 'package:unishare_mobile/features/post_feed/presentation/widgets/post_card_widget.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _GuestModeOn extends GuestMode {
  @override
  bool build() => true;
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  Future<AppUser> signInWithGoogle() async => throw UnimplementedError();

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<AppUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? universityId,
  }) async => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser?> getCurrentUser() async => null;

  @override
  Future<void> updateAcademicProfile({
    required String uid,
    required String departmentId,
    int? enrollmentYear,
  }) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildSubject({bool guestMode = false}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      if (guestMode) guestModeProvider.overrideWith(() => _GuestModeOn()),
    ],
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: const FeedScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('FeedScreen — logged-in', () {
    testWidgets('renders the Feed title in the app bar', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      expect(find.text('Feed'), findsOneWidget);
    });

    testWidgets('renders search field with correct hint text', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      expect(find.text('Search posts or #tags...'), findsOneWidget);
    });

    testWidgets('renders three tabs: ALL, NOTES, ASSIGNMENTS', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('NOTES'), findsOneWidget);
      expect(find.text('ASSIGNMENTS'), findsOneWidget);
    });

    testWidgets('renders Filters button', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      expect(find.text('Filters'), findsOneWidget);
    });

    testWidgets('renders post cards in ALL tab (viewport may clip the list)', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      // ListView lazily builds only visible items; the default 800×600 test
      // viewport renders at least 4 of the 6 mock cards.
      expect(find.byType(PostCardWidget), findsAtLeastNWidgets(4));
    });

    testWidgets('renders logged-in bottom nav with FEED POSTS NOTIFS MORE', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('FEED'), findsOneWidget);
      expect(find.text('POSTS'), findsOneWidget);
      expect(find.text('NOTIFS'), findsOneWidget);
      expect(find.text('MORE'), findsOneWidget);
    });

    testWidgets('shows create-post button for logged-in user', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('tapping NOTES tab filters to 4 note cards', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      await tester.tap(find.text('NOTES'));
      await tester.pumpAndSettle();

      expect(find.byType(PostCardWidget), findsNWidgets(4));
    });

    testWidgets('tapping ASSIGNMENTS tab filters to 2 assignment cards', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      await tester.tap(find.text('ASSIGNMENTS'));
      await tester.pumpAndSettle();

      expect(find.byType(PostCardWidget), findsNWidgets(2));
    });

    testWidgets('post card shows title text', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      expect(find.text('LR Parsing'), findsOneWidget);
    });

    testWidgets('post card shows course code', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      expect(find.text('CSC233'), findsWidgets);
    });

    testWidgets('post card shows author name', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      expect(find.text('La Yaung Phyo'), findsWidgets);
    });

    testWidgets('tapping Filters button opens filter picker sheet', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Filter by tags'), findsOneWidget);
    });

    testWidgets('filter picker shows Confirm and Clear buttons', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('active tag filter shows only matching posts', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();

      // Scope to the sheet widget to avoid ambiguity with post card tag chips
      final inSheet = find.descendant(
        of: find.byType(FilterPickerWidget),
        matching: find.text('concurrency'),
      );
      await tester.tap(inSheet);
      await tester.pump();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // only 1 mock post has 'concurrency' tag (Chapter 7)
      expect(find.byType(PostCardWidget), findsNWidgets(1));
    });

    testWidgets('no-match filter shows empty state widget', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      // ASSIGNMENTS tab — no assignment posts have the 'concurrency' tag
      await tester.tap(find.text('ASSIGNMENTS'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();

      final inSheet = find.descendant(
        of: find.byType(FilterPickerWidget),
        matching: find.text('concurrency'),
      );
      await tester.tap(inSheet);
      await tester.pump();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.byType(FeedEmptyStateWidget), findsOneWidget);
    });
  });

  group('FeedScreen — guest mode', () {
    testWidgets('shows FEED SAVED SIGN IN bottom nav for guest', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(guestMode: true));
      await tester.pump();

      expect(find.text('FEED'), findsOneWidget);
      expect(find.text('SAVED'), findsOneWidget);
      expect(find.text('SIGN IN'), findsOneWidget);
    });

    testWidgets('hides create-post button for guest user', (tester) async {
      await tester.pumpWidget(_buildSubject(guestMode: true));
      await tester.pump();

      expect(find.byIcon(Icons.add), findsNothing);
    });
  });

  group('PostCardWidget', () {
    testWidgets('note type shows NOTE badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: const Scaffold(
            body: PostCardWidget(
              post: MockPost(
                type: MockPostType.note,
                courseCode: 'CSC101',
                title: 'Test Note',
                authorInitials: 'AB',
                authorName: 'Author Name',
                authorYear: 1,
                commentCount: 3,
                timeAgo: '2 days ago',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('NOTE'), findsOneWidget);
      expect(find.text('Test Note'), findsOneWidget);
      expect(find.text('CSC101'), findsOneWidget);
    });

    testWidgets('assignment type shows ASSIGNMENT badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: const Scaffold(
            body: PostCardWidget(
              post: MockPost(
                type: MockPostType.assignment,
                courseCode: 'MTH200',
                title: 'Homework 1',
                authorInitials: 'XY',
                authorName: 'Test User',
                authorYear: 2,
                commentCount: 0,
                timeAgo: '5 days ago',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('ASSIGNMENT'), findsOneWidget);
      expect(find.text('Homework 1'), findsOneWidget);
    });

    testWidgets('renders topic tag chips when tags are provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: PostCardWidget(
                post: MockPost(
                  type: MockPostType.note,
                  courseCode: 'CSC217',
                  title: 'Chapter 7',
                  topicTags: ['concurrency', 'os'],
                  authorInitials: 'S',
                  authorName: 'Slade',
                  authorYear: 2,
                  commentCount: 0,
                  timeAgo: '19 days ago',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('concurrency'), findsOneWidget);
      expect(find.text('os'), findsOneWidget);
    });

    testWidgets('renders comment count with label and time ago in meta row', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: const Scaffold(
            body: PostCardWidget(
              post: MockPost(
                type: MockPostType.note,
                courseCode: 'CSC101',
                title: 'Sample',
                authorInitials: 'AB',
                authorName: 'Alice',
                authorYear: 1,
                commentCount: 7,
                timeAgo: '3 hours ago',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('7 comments'), findsOneWidget);
      expect(find.text('3 hours ago'), findsOneWidget);
    });

    testWidgets('singular comment count shows "1 comment"', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: const Scaffold(
            body: PostCardWidget(
              post: MockPost(
                type: MockPostType.note,
                courseCode: 'CSC101',
                title: 'Sample',
                authorInitials: 'AB',
                authorName: 'Alice',
                authorYear: 1,
                commentCount: 1,
                timeAgo: '1 hour ago',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1 comment'), findsOneWidget);
    });
  });
}
