import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:unishare_mobile/features/auth/domain/entities/auth_exception.dart';

// ---------------------------------------------------------------------------
// Minimal FirebaseAuth stub that never calls Firebase SDK
// ---------------------------------------------------------------------------

class _StubFirebaseAuth extends Fake implements FirebaseAuth {
  @override
  Stream<User?> authStateChanges() => const Stream.empty();

  @override
  User? get currentUser => null;
}

// ---------------------------------------------------------------------------
// Fake FirebaseAuthDatasource — injects stub FirebaseAuth so no SDK call
// ---------------------------------------------------------------------------

class FakeFirebaseAuthDatasource extends FirebaseAuthDatasource {
  FakeFirebaseAuthDatasource() : super(firebaseAuth: _StubFirebaseAuth());

  String nextUid = 'test-uid';
  bool isNewUser = true;
  AuthException? throwOnSignIn;
  int createUserCallCount = 0;

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<FakeUserCredential?> signInWithGoogle() async {
    if (throwOnSignIn != null) throw throwOnSignIn!;
    return FakeUserCredential(uid: nextUid, isNewUser: isNewUser);
  }

  @override
  Future<FakeUserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (throwOnSignIn != null) throw throwOnSignIn!;
    return FakeUserCredential(uid: nextUid, isNewUser: false);
  }

  @override
  Future<FakeUserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    createUserCallCount++;
    return FakeUserCredential(uid: nextUid, isNewUser: true);
  }

  @override
  Future<void> signOut() async {}
}

// ---------------------------------------------------------------------------
// Supporting fakes — package-visible so auth_repository_impl_test can use them
// ---------------------------------------------------------------------------

class FakeFirebaseUser extends Fake implements User {
  FakeFirebaseUser({required this.uid});

  @override
  final String uid;

  @override
  String? get displayName => null;

  @override
  String? get email => null;

  @override
  String? get photoURL => null;
}

class FakeAdditionalUserInfo extends Fake implements AdditionalUserInfo {
  FakeAdditionalUserInfo({required this.isNewUser});

  @override
  final bool isNewUser;
}

class FakeUserCredential extends Fake implements UserCredential {
  FakeUserCredential({required String uid, required bool isNewUser})
    : user = FakeFirebaseUser(uid: uid),
      additionalUserInfo = FakeAdditionalUserInfo(isNewUser: isNewUser);

  @override
  final User user;

  @override
  final AdditionalUserInfo additionalUserInfo;
}
