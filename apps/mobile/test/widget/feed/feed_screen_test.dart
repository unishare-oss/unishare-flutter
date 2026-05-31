import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/feed/presentation/providers/feed_filter_provider.dart';
import 'package:unishare_mobile/features/feed/presentation/providers/feed_provider.dart';
import 'package:unishare_mobile/features/feed/presentation/screens/feed_screen.dart';
import 'package:unishare_mobile/features/feed/presentation/widgets/feed_empty_state_widget.dart';
import 'package:unishare_mobile/features/feed/presentation/widgets/post_card.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/is_post_saved_provider.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _PresetFeedFilter extends FeedFilter {
  _PresetFeedFilter(this._initial);
  final FeedFilterState _initial;
  @override
  FeedFilterState build() => _initial;
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  Future<AppUser> signInAnonymously() async => throw UnimplementedError();

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
  Future<void> updateProfile({
    required String uid,
    required String name,
    String? bio,
    String? universityId,
    String? departmentId,
    int? enrollmentYear,
  }) => throw UnimplementedError();

  @override
  Future<void> updateAcademicProfile({
    required String uid,
    required String departmentId,
    int? enrollmentYear,
  }) async {}
}

// ---------------------------------------------------------------------------
// Mock feed data
// ---------------------------------------------------------------------------

Post _post({
  required String id,
  required PostType type,
  required String courseId,
  required String title,
  required String authorName,
  List<String> tags = const [],
}) => Post(
  id: id,
  authorId: 'uid',
  authorName: authorName,
  authorAvatar: '',
  postType: type,
  year: 1,
  courseId: courseId,
  title: title,
  description: '',
  postingIdentity: PostingIdentity.named,
  semester: 1,
  moduleNumber: '',
  mediaUrls: const [],
  tags: tags,
  likesCount: 0,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

final _mockFeed = [
  _post(
    id: '1',
    type: PostType.lectureNote,
    courseId: 'CSC233',
    title: 'LR Parsing',
    authorName: 'Test User',
  ),
  _post(
    id: '2',
    type: PostType.lectureNote,
    courseId: 'CSC220',
    title: 'TCP Congestion',
    authorName: 'Test User',
    tags: ['networking'],
  ),
  _post(
    id: '3',
    type: PostType.lectureNote,
    courseId: 'CSC220',
    title: 'Gemini Notes',
    authorName: 'Test User',
    tags: ['networking'],
  ),
  _post(
    id: '4',
    type: PostType.lectureNote,
    courseId: 'CSC217',
    title: 'Chapter 7',
    authorName: 'Test User',
    tags: ['concurrency', 'os'],
  ),
  _post(
    id: '5',
    type: PostType.exercise,
    courseId: 'CSC233',
    title: 'Assignment 9',
    authorName: 'Test User',
  ),
  _post(
    id: '6',
    type: PostType.exercise,
    courseId: 'GEN231',
    title: 'M2 Final',
    authorName: 'Test User',
  ),
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildSubject({
  bool guestMode = false,
  FeedFilterState feedFilter = const FeedFilterState(),
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      if (guestMode) guestModeProvider.overrideWithValue(true),
      feedProvider.overrideWith((_) => Stream.value(_mockFeed)),
      feedFilterProvider.overrideWith(() => _PresetFeedFilter(feedFilter)),
    ],
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: FeedScreen(scrollKey: GlobalKey()),
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

    testWidgets('renders three tabs: ALL, NOTES, EXERCISES', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('NOTES'), findsOneWidget);
      expect(find.text('EXERCISES'), findsOneWidget);
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

      // ListView lazily builds only visible items; the default 800x600 test
      // viewport renders at least 4 of the 6 mock cards.
      expect(find.byType(PostCard), findsAtLeastNWidgets(4));
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

      expect(find.byType(PostCard), findsNWidgets(4));
    });

    testWidgets('tapping EXERCISES tab filters to 2 exercise cards', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      await tester.tap(find.text('EXERCISES'));
      await tester.pumpAndSettle();

      expect(find.byType(PostCard), findsNWidgets(2));
    });

    testWidgets('post card shows title text', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      expect(find.text('LR Parsing'), findsOneWidget);
    });

    testWidgets('post card shows post title', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      expect(find.text('TCP Congestion'), findsOneWidget);
    });

    testWidgets('post card shows author name', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      expect(find.text('Test User'), findsWidgets);
    });

    testWidgets('tapping Filters button opens filter drawer', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Filter posts'), findsOneWidget);
    });

    testWidgets('filter drawer shows Clear and Apply buttons', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
    });

    testWidgets('courseId filter shows only matching posts', (tester) async {
      // CSC233 has 2 posts: 'LR Parsing' (note) + 'Assignment 9' (exercise)
      await tester.pumpWidget(
        _buildSubject(
          feedFilter: const FeedFilterState(
            courseId: 'CSC233',
            courseName: 'CS',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PostCard), findsNWidgets(2));
      expect(find.text('LR Parsing'), findsOneWidget);
    });

    testWidgets('no-match courseId filter shows empty state widget', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(
          feedFilter: const FeedFilterState(
            courseId: 'NO_MATCH',
            courseName: 'x',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FeedEmptyStateWidget), findsOneWidget);
    });
  });

  group('FeedScreen — guest mode', () {
    testWidgets('hides create-post button for guest user', (tester) async {
      await tester.pumpWidget(_buildSubject(guestMode: true));
      await tester.pump();

      expect(find.byIcon(Icons.add), findsNothing);
    });
  });

  group('PostCard', () {
    Widget card(Post post) => ProviderScope(
      overrides: [
        isPostSavedProvider(post.id).overrideWith((_) => Stream.value(false)),
      ],
      child: MaterialApp(
        theme: AppTheme.build(AppThemes.unishare),
        home: Scaffold(
          body: SingleChildScrollView(child: PostCard(post: post)),
        ),
      ),
    );

    testWidgets('note type shows NOTE badge', (tester) async {
      await tester.pumpWidget(
        card(
          _post(
            id: 'a',
            type: PostType.lectureNote,
            courseId: 'CSC101',
            title: 'Test Note',
            authorName: 'Alice',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('NOTE'), findsOneWidget);
      expect(find.text('Test Note'), findsOneWidget);
      expect(find.text('CSC101'), findsOneWidget);
    });

    testWidgets('exercise type shows EXERCISE badge', (tester) async {
      await tester.pumpWidget(
        card(
          _post(
            id: 'b',
            type: PostType.exercise,
            courseId: 'MTH200',
            title: 'HW1',
            authorName: 'Bob',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('EXERCISE'), findsOneWidget);
      expect(find.text('HW1'), findsOneWidget);
    });

    testWidgets('renders tag chips when tags are present', (tester) async {
      await tester.pumpWidget(
        card(
          _post(
            id: 'c',
            type: PostType.lectureNote,
            courseId: 'CSC217',
            title: 'Ch7',
            authorName: 'Carol',
            tags: ['concurrency', 'os'],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('concurrency'), findsOneWidget);
      expect(find.text('os'), findsOneWidget);
    });

    testWidgets('renders no Wrap when post has no tags', (tester) async {
      await tester.pumpWidget(
        card(
          _post(
            id: 'd',
            type: PostType.lectureNote,
            courseId: 'CSC101',
            title: 'No Tags',
            authorName: 'Dave',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('renders author name and like count', (tester) async {
      await tester.pumpWidget(
        card(
          _post(
            id: 'e',
            type: PostType.lectureNote,
            courseId: 'CSC101',
            title: 'T',
            authorName: 'Eve',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Eve'), findsOneWidget);
      expect(find.text('0 likes'), findsOneWidget);
    });
  });
}
