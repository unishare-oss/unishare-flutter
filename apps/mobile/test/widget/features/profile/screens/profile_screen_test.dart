import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/departments_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/universities_provider.dart';
import 'package:unishare_mobile/features/post/domain/repositories/comment_repository.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';
import 'package:unishare_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/saved_posts_provider.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

import '../../../../unit/features/post/fakes/fake_comment_repository.dart';
import '../../../../unit/features/post/fakes/fake_post_repository.dart';

// ---------------------------------------------------------------------------
// Fakes — auth repository capturing what's saved so we can assert on it
// ---------------------------------------------------------------------------

class _FakeAuthRepository implements AuthRepository {
  String? lastUid;
  String? lastName;
  String? lastBio;
  String? lastUniversityId;
  String? lastDepartmentId;
  int? lastEnrollmentYear;
  int saveCallCount = 0;
  bool throwOnSignOut = false;
  Exception? throwOnUpdate;

  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  Future<AppUser> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AppUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? universityId,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {
    if (throwOnSignOut) throw Exception('network error');
  }

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
  }) async {
    saveCallCount++;
    if (throwOnUpdate != null) throw throwOnUpdate!;
    lastUid = uid;
    lastName = name;
    lastBio = bio;
    lastUniversityId = universityId;
    lastDepartmentId = departmentId;
    lastEnrollmentYear = enrollmentYear;
  }

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

const _testUser = AppUser(
  id: 'u1',
  name: 'Alex Tester',
  email: 'alex@example.com',
);

/// Builds the ProfileScreen with all upstream providers stubbed out so the
/// test never touches Firebase, Hive, or the network.
Widget _buildSubject({
  AppUser? user = _testUser,
  AuthRepository? authRepository,
  PostRepository? postRepository,
  CommentRepository? commentRepository,
}) {
  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(
        path: '/welcome',
        builder: (_, _) => const Scaffold(body: Text('welcome')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) async => user),
      savedPostsProvider.overrideWith(
        (ref) => Stream<List<SavedPost>>.value(const []),
      ),
      departmentsProvider.overrideWith((ref) => Stream.value(const [])),
      universitiesProvider.overrideWith((ref) => Stream.value(const [])),
      postRepositoryProvider.overrideWithValue(
        postRepository ?? FakePostRepository(),
      ),
      commentRepositoryProvider.overrideWithValue(
        commentRepository ?? FakeCommentRepository(),
      ),
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
    ],
    child: MaterialApp.router(
      theme: AppTheme.build(AppThemes.unishare),
      routerConfig: router,
    ),
  );
}

/// Tall surface so the form, year field, and Save button all fit on screen
/// without scrolling. Prevents flaky offscreen-tap failures.
Future<void> _useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  group('ProfileScreen', () {
    testWidgets('renders Profile title in app bar', (tester) async {
      await _useTallSurface(tester);
      await tester.pumpWidget(_buildSubject());
      await tester.pump(); // first frame
      await tester.pump(); // currentUserProvider resolves

      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('shows sign-in prompt when user is null', (tester) async {
      await _useTallSurface(tester);
      await tester.pumpWidget(_buildSubject(user: null));
      await tester.pump();
      await tester.pump();

      expect(find.text('Sign in to view your profile'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    });

    testWidgets('save with empty display name shows validation error', (
      tester,
    ) async {
      await _useTallSurface(tester);
      final auth = _FakeAuthRepository();
      await tester.pumpWidget(_buildSubject(authRepository: auth));
      await tester.pumpAndSettle();

      // Clear the name field.
      await tester.enterText(find.byType(TextField).first, '');

      // Tap save.
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();

      expect(find.text('Display name is required'), findsOneWidget);
      expect(auth.saveCallCount, 0);
    });

    testWidgets('save with future enrollment year shows validation error', (
      tester,
    ) async {
      await _useTallSurface(tester);
      final auth = _FakeAuthRepository();
      await tester.pumpWidget(_buildSubject(authRepository: auth));
      await tester.pumpAndSettle();

      // Enrollment year is the only TextFormField on the screen (name/bio
      // use plain TextField).
      final yearField = find.byType(TextFormField);
      expect(yearField, findsOneWidget);
      await tester.enterText(yearField, '${DateTime.now().year + 5}');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump(); // schedule snackbar
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.textContaining('Enrollment year must be between'),
        findsOneWidget,
      );
      expect(auth.saveCallCount, 0);
    });

    testWidgets('valid save calls authRepository.updateProfile', (
      tester,
    ) async {
      await _useTallSurface(tester);
      final auth = _FakeAuthRepository();
      await tester.pumpWidget(_buildSubject(authRepository: auth));
      await tester.pumpAndSettle();

      // Name stays as seeded ('Alex Tester'); just tap Save.
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(auth.saveCallCount, 1);
      expect(auth.lastUid, 'u1');
      expect(auth.lastName, 'Alex Tester');
      expect(find.text('Profile saved'), findsOneWidget);
    });

    testWidgets('sign-out failure shows error snackbar', (tester) async {
      await _useTallSurface(tester);
      final auth = _FakeAuthRepository()..throwOnSignOut = true;
      await tester.pumpWidget(_buildSubject(authRepository: auth));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(find.text('Sign out failed. Please try again.'), findsOneWidget);
    });
  });
}
