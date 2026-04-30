import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/auth/data/models/app_user_model.dart';
import 'package:unishare_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:unishare_mobile/features/auth/domain/entities/auth_exception.dart';

import 'fakes/fake_firebase_auth_datasource.dart';
import 'fakes/fake_firestore_user_datasource.dart';

void main() {
  group('AuthRepositoryImpl', () {
    late FakeFirebaseAuthDatasource fakeAuth;
    late FakeFirestoreUserDatasource fakeFirestore;
    late AuthRepositoryImpl repo;

    setUp(() {
      fakeAuth = FakeFirebaseAuthDatasource();
      fakeFirestore = FakeFirestoreUserDatasource();
      repo = AuthRepositoryImpl(
        authDatasource: fakeAuth,
        firestoreDatasource: fakeFirestore,
      );
    });

    group('signInWithEmail', () {
      test(
        'returns AppUser mapped from Firebase user + Firestore doc',
        () async {
          fakeAuth.nextUid = 'uid-123';
          fakeFirestore.storedUsers['uid-123'] = AppUserModel(
            id: 'uid-123',
            name: 'Alice',
            email: 'alice@example.com',
          );

          final user = await repo.signInWithEmail(
            email: 'alice@example.com',
            password: 'secret',
          );

          expect(user.id, 'uid-123');
          expect(user.name, 'Alice');
          expect(user.email, 'alice@example.com');
        },
      );

      test('propagates AuthException from datasource', () async {
        fakeAuth.throwOnSignIn = const AuthException(
          AuthFailureType.invalidCredentials,
        );

        expect(
          () =>
              repo.signInWithEmail(email: 'bad@example.com', password: 'wrong'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.type,
              'type',
              AuthFailureType.invalidCredentials,
            ),
          ),
        );
      });
    });

    group('signInWithGoogle', () {
      test('creates Firestore doc on first sign-in', () async {
        fakeAuth.nextUid = 'uid-google-new';
        fakeAuth.isNewUser = true;

        final user = await repo.signInWithGoogle();

        expect(fakeFirestore.storedUsers.containsKey('uid-google-new'), isTrue);
        expect(user.id, 'uid-google-new');
      });

      test('does NOT create Firestore doc for returning user', () async {
        fakeAuth.nextUid = 'uid-google-existing';
        fakeAuth.isNewUser = false;
        fakeFirestore.storedUsers['uid-google-existing'] = AppUserModel(
          id: 'uid-google-existing',
          name: 'Bob',
          email: 'bob@example.com',
        );

        final user = await repo.signInWithGoogle();

        expect(user.name, 'Bob');
        // createUser was not called a second time — count stays at 0 for this uid
        expect(fakeFirestore.createUserCallCount, 0);
      });
    });

    group('signUpWithEmail', () {
      test('creates both Firebase user and Firestore doc', () async {
        fakeAuth.nextUid = 'uid-new-email';

        final user = await repo.signUpWithEmail(
          name: 'Carol',
          email: 'carol@example.com',
          password: 'secret123',
        );

        expect(fakeAuth.createUserCallCount, 1);
        expect(fakeFirestore.createUserCallCount, 1);
        expect(
          fakeFirestore.consentWrittenForUids.contains('uid-new-email'),
          isTrue,
        );
        expect(user.id, 'uid-new-email');
        expect(user.name, 'Carol');
      });
    });
  });
}
