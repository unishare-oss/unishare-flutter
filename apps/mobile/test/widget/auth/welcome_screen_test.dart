import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/screens/welcome_screen.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

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

Widget _buildSubject() {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
    ],
    child: const MaterialApp(home: WelcomeScreen()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('WelcomeScreen', () {
    testWidgets(
      'renders Google button, email link, create account link, guest link',
      (tester) async {
        await tester.pumpWidget(_buildSubject());
        await tester.pump();

        expect(find.text('Continue with Google'), findsOneWidget);
        expect(find.text('Sign in with email'), findsOneWidget);
        expect(find.text('Create account'), findsOneWidget);
        expect(find.text('Continue as guest'), findsOneWidget);
      },
    );

    testWidgets('tapping "Continue as guest" sets guestMode to true', (
      tester,
    ) async {
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const MaterialApp(home: WelcomeScreen());
            },
          ),
        ),
      );
      await tester.pump();

      expect(capturedRef.read(guestModeProvider), isFalse);

      await tester.tap(find.text('Continue as guest'));
      await tester.pump();

      expect(capturedRef.read(guestModeProvider), isTrue);
    });
  });
}
