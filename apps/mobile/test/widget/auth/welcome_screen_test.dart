import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/universities_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/screens/welcome_screen.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

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
// Helper
// ---------------------------------------------------------------------------

Widget _buildSubject() {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      universitiesProvider.overrideWith(
        (ref) => Stream.value(<({String id, String name})>[]),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: const AuthScreen(),
    ),
  );
}

/// Finds the "Sign up" TextButton in the mode-switch row (not the submit
/// FilledButton which reads "Create account").
Finder get _signUpLink => find.descendant(
  of: find.byType(Row),
  matching: find.widgetWithText(TextButton, 'Sign up'),
);

Finder get _signInLink => find.descendant(
  of: find.byType(Row),
  matching: find.widgetWithText(TextButton, 'Sign in'),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AuthScreen — sign-in mode', () {
    testWidgets(
      'renders Google button, Microsoft button, email/password fields, '
      'mode-switch link and guest link',
      (tester) async {
        await tester.pumpWidget(_buildSubject());
        await tester.pump();

        expect(find.text('Continue with Google'), findsOneWidget);
        expect(find.text('Continue with Microsoft'), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(_signUpLink, findsOneWidget);
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
            universitiesProvider.overrideWith(
              (ref) => Stream.value(<({String id, String name})>[]),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return MaterialApp(
                theme: AppTheme.build(AppThemes.unishare),
                home: const AuthScreen(),
              );
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

  group('AuthScreen — sign-up mode', () {
    /// Switches to sign-up mode by tapping the "Sign up" link.
    Future<void> switchToSignUp(WidgetTester tester) async {
      await tester.tap(_signUpLink);
      await tester.pumpAndSettle();
    }

    testWidgets(
      'switching to sign-up shows name, email, password, confirm, consent',
      (tester) async {
        await tester.pumpWidget(_buildSubject());
        await tester.pump();

        await switchToSignUp(tester);

        // Heading changed
        expect(find.text('Create account'), findsWidgets);

        // 4 TextFormFields: name, email, password, confirm password
        // (university dropdown is a DropdownButtonFormField, not TextFormField)
        expect(find.byType(TextFormField), findsNWidgets(4));

        // Consent checkbox
        expect(find.byType(Checkbox), findsOneWidget);

        // Mode-switch now shows sign-in link
        expect(_signInLink, findsOneWidget);

        // OAuth footnote visible
        expect(
          find.text(
            'By continuing with Google or Microsoft you agree to our Terms and Privacy Policy.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('submit with mismatched passwords shows inline error', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      await switchToSignUp(tester);

      final fields = find.byType(TextFormField);
      // fields: 0=name, 1=email, 2=password, 3=confirm password
      await tester.enterText(fields.at(0), 'Test User');
      await tester.enterText(fields.at(1), 'test@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'different456');

      // Scroll to and check the consent checkbox so the button is enabled
      final checkbox = find.byType(Checkbox);
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox, warnIfMissed: false);
      await tester.pump();

      final submitButton = find.widgetWithText(FilledButton, 'Create account');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton, warnIfMissed: false);
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('submit without consent shows consent error', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();

      await switchToSignUp(tester);

      // The submit button should be disabled (consent not checked)
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Create account'),
      );
      expect(button.onPressed, isNull);
    });
  });
}
