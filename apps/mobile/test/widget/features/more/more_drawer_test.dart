import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_grid.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_user_row.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.user, this.throwOnSignOut = false});

  AppUser? user;
  int signOutCalls = 0;
  bool throwOnSignOut;

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(user);

  @override
  Future<AppUser?> getCurrentUser() async => user;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (throwOnSignOut) throw Exception('network error');
  }

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
  Future<void> updateProfile({
    required String uid,
    required String name,
    String? bio,
    String? universityId,
    String? departmentId,
    int? enrollmentYear,
  }) async {}
  @override
  Future<void> updateAcademicProfile({
    required String uid,
    required String departmentId,
    int? enrollmentYear,
  }) async {}
}

const _user = AppUser(
  id: 'u1',
  name: 'Pyae Sone',
  email: 'p@example.com',
  role: 'student',
);

GoRouter _testRouter() => GoRouter(
  initialLocation: '/host',
  routes: [
    GoRoute(
      path: '/host',
      builder: (ctx, _) => Scaffold(
        body: Builder(
          builder: (innerCtx) => Center(
            child: ElevatedButton(
              onPressed: () => showMoreDrawer(innerCtx),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/profile',
      builder: (_, _) => const Scaffold(body: Text('Profile page')),
    ),
    GoRoute(
      path: '/saved',
      builder: (_, _) => const Scaffold(body: Text('Saved page')),
    ),
    GoRoute(
      path: '/departments',
      builder: (_, _) => const Scaffold(body: Text('Departments page')),
    ),
    GoRoute(
      path: '/requests',
      builder: (_, _) => const Scaffold(body: Text('Requests page')),
    ),
    GoRoute(
      path: '/welcome',
      builder: (_, _) => const Scaffold(body: Text('Welcome page')),
    ),
  ],
);

Widget _buildApp(_FakeAuthRepository repo) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(
      theme: AppTheme.build(AppThemes.unishare),
      routerConfig: _testRouter(),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('OPEN'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders user row, 4-tile grid, and sign out row', (
    tester,
  ) async {
    final repo = _FakeAuthRepository(user: _user);
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();
    await _openSheet(tester);

    expect(find.byType(MoreDrawerUserRow), findsOneWidget);
    expect(find.byType(MoreDrawerGrid), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('does NOT render an ADMIN section label', (tester) async {
    final repo = _FakeAuthRepository(user: _user);
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();
    await _openSheet(tester);

    // ADMIN appears in the user role badge but NOT as a section header.
    // 'student' role means no role badge of 'ADMIN' should exist anywhere.
    expect(find.text('ADMIN'), findsNothing);
  });

  testWidgets('tapping SAVED tile navigates to /saved', (tester) async {
    final repo = _FakeAuthRepository(user: _user);
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();
    await _openSheet(tester);

    await tester.tap(find.text('SAVED'));
    await tester.pumpAndSettle();

    expect(find.text('Saved page'), findsOneWidget);
  });

  testWidgets('tapping DEPARTMENTS tile navigates to /departments', (
    tester,
  ) async {
    final repo = _FakeAuthRepository(user: _user);
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();
    await _openSheet(tester);

    await tester.tap(find.text('DEPARTMENTS'));
    await tester.pumpAndSettle();

    expect(find.text('Departments page'), findsOneWidget);
  });

  testWidgets('tapping REQUESTS tile navigates to /requests', (tester) async {
    final repo = _FakeAuthRepository(user: _user);
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();
    await _openSheet(tester);

    await tester.tap(find.text('REQUESTS'));
    await tester.pumpAndSettle();

    expect(find.text('Requests page'), findsOneWidget);
  });

  testWidgets('tapping PROFILE tile navigates to /profile', (tester) async {
    final repo = _FakeAuthRepository(user: _user);
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();
    await _openSheet(tester);

    await tester.tap(find.text('PROFILE'));
    await tester.pumpAndSettle();

    expect(find.text('Profile page'), findsOneWidget);
  });

  testWidgets(
    'tapping Sign out then confirming calls signOut and exits guest mode',
    (tester) async {
      final repo = _FakeAuthRepository(user: _user);
      await tester.pumpWidget(_buildApp(repo));
      await tester.pumpAndSettle();
      await _openSheet(tester);

      // First tap opens the confirmation dialog — signOut should NOT have
      // fired yet.
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(repo.signOutCalls, 0);

      // Confirm via the dialog's Sign out button.
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Sign out'),
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.signOutCalls, 1);
    },
  );

  testWidgets('cancelling the sign-out dialog leaves the session intact', (
    tester,
  ) async {
    final repo = _FakeAuthRepository(user: _user);
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();
    await _openSheet(tester);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'Cancel'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(repo.signOutCalls, 0);
  });

  testWidgets('sign-out failure shows error snackbar', (tester) async {
    final repo = _FakeAuthRepository(user: _user, throwOnSignOut: true);
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();
    await _openSheet(tester);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'Sign out'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign out failed. Please try again.'), findsOneWidget);
  });
}
