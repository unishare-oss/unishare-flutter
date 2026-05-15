import 'package:firebase_auth/firebase_auth.dart' show User;

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:unishare_mobile/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:unishare_mobile/features/auth/data/datasources/firestore_user_datasource.dart';

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
      final providerIds = _providerIds(firebaseUser);
      final model = await _firestore.getUser(firebaseUser.uid);
      // Fall back to Firebase Auth data if the Firestore document doesn't
      // exist yet (new-user race condition) or was never created.
      // departmentId=null triggers the academic profile prompt on first launch.
      return model?.toEntity(providerIds: providerIds) ??
          AppUser(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? '',
            email: firebaseUser.email ?? '',
            photoUrl: firebaseUser.photoURL,
            providerIds: providerIds,
          );
    });
  }

  List<String> _providerIds(User user) =>
      user.providerData.map((p) => p.providerId).toList(growable: false);

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
    final providerIds = _providerIds(firebaseUser);

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
        providerIds: providerIds,
      );
    }

    final model = await _firestore.getUser(firebaseUser.uid);
    return model!.toEntity(providerIds: providerIds);
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
    final firebaseUser = credential.user!;
    final model = await _firestore.getUser(firebaseUser.uid);
    return model!.toEntity(providerIds: _providerIds(firebaseUser));
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

    // Set displayName on the Firebase Auth profile so it's available
    // when creating posts (PostRepositoryImpl reads user.displayName).
    await credential.user!.updateDisplayName(name);

    await _firestore.createUser(
      uid: uid,
      name: name,
      email: email,
      universityId: universityId,
      withConsent: true,
    );

    return AppUser(
      id: uid,
      name: name,
      email: email,
      universityId: universityId,
      providerIds: _providerIds(credential.user!),
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    final providerIds = _providerIds(firebaseUser);
    final model = await _firestore.getUser(firebaseUser.uid);
    return model?.toEntity(providerIds: providerIds);
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String name,
    String? bio,
    String? universityId,
    String? departmentId,
    int? enrollmentYear,
  }) => _firestore.updateProfile(
    uid: uid,
    name: name,
    bio: bio,
    universityId: universityId,
    departmentId: departmentId,
    enrollmentYear: enrollmentYear,
  );

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

  @override
  Stream<int> watchCommentCountByAuthor(String uid) =>
      _firestore.streamCommentCountByAuthor(uid);
}
