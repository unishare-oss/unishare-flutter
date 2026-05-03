import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../datasources/firestore_user_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required FirebaseAuthDatasource authDatasource,
    required FirestoreUserDatasource firestoreDatasource,
  }) : _auth = authDatasource,
       _firestore = firestoreDatasource;

  final FirebaseAuthDatasource _auth;
  final FirestoreUserDatasource _firestore;

  @override
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      final model = await _firestore.getUser(firebaseUser.uid);
      if (model == null) return null;
      return model.toEntity();
    });
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final credential = await _auth.signInWithGoogle();
    // User cancelled — silently return guest-like behaviour by throwing,
    // but the caller (provider) handles null credential as a no-op.
    if (credential == null) {
      throw StateError('Google sign-in cancelled');
    }

    final firebaseUser = credential.user!;
    final isNew = credential.additionalUserInfo?.isNewUser ?? false;

    if (isNew) {
      await _firestore.createUser(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
      );
      return AppUser(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
      );
    }

    final model = await _firestore.getUser(firebaseUser.uid);
    return model!.toEntity();
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final model = await _firestore.getUser(credential.user!.uid);
    return model!.toEntity();
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? universityId,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    await _firestore.createUser(
      uid: uid,
      name: name,
      email: email,
      universityId: universityId,
      withConsent: true,
    );

    return AppUser(id: uid, name: name, email: email, universityId: universityId);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    final model = await _firestore.getUser(firebaseUser.uid);
    return model?.toEntity();
  }

  @override
  Future<void> updateAcademicProfile({
    required String uid,
    required String departmentId,
    int? enrollmentYear,
  }) => _firestore.updateAcademicProfile(
    uid: uid,
    departmentId: departmentId,
    enrollmentYear: enrollmentYear,
  );
}
