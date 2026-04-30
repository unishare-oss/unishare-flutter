import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/auth/data/datasources/firestore_user_datasource.dart';
import 'package:unishare_mobile/features/auth/presentation/screens/sign_up_screen.dart';

class _StubFirestore extends Fake implements FirebaseFirestore {}

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

class _FakeFirestoreUserDatasource extends FirestoreUserDatasource {
  _FakeFirestoreUserDatasource() : super(firestore: _StubFirestore());

  @override
  Stream<List<({String id, String name})>> getUniversities() =>
      Stream.value([]);

  @override
  Stream<List<({String id, String name})>> getDepartments() => Stream.value([]);
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _buildSubject() {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      firestoreUserDatasourceProvider.overrideWithValue(
        _FakeFirestoreUserDatasource(),
      ),
    ],
    child: const MaterialApp(home: SignUpScreen()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SignUpScreen', () {
    testWidgets('password mismatch shows inline error', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      // Fill name and email so those validators pass
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Test User');
      await tester.enterText(fields.at(1), 'test@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'different456');

      // Check consent
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // Scroll to the button before tapping — the form may exceed the viewport.
      final submitButton = find.widgetWithText(FilledButton, 'Create account');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('submit button disabled when consent not checked', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      // Fill valid form data but do NOT check consent
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Test User');
      await tester.enterText(fields.at(1), 'test@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password123');

      await tester.pump();

      // Find the "Create account" FilledButton and verify it is disabled
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Create account'),
      );
      expect(button.onPressed, isNull);
    });
  });
}
