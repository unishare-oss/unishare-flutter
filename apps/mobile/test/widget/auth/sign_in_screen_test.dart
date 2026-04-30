import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/screens/sign_in_screen.dart';

// ---------------------------------------------------------------------------
// Fake
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
// Helper
// ---------------------------------------------------------------------------

Widget _buildSubject() {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
    ],
    child: const MaterialApp(home: SignInScreen()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SignInScreen', () {
    testWidgets('shows validation errors for empty fields on submit', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      // Tap the Sign in FilledButton (not the AppBar title)
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email format', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      // Enter an invalid email
      await tester.enterText(find.byType(TextFormField).first, 'notanemail');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pump();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });
  });
}
