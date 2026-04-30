import '../entities/app_user.dart';

abstract interface class AuthRepository {
  /// Emits null when signed out, AppUser when signed in.
  Stream<AppUser?> get authStateChanges;

  Future<AppUser> signInWithGoogle();

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? universityId,
  });

  Future<void> signOut();

  Future<AppUser?> getCurrentUser();

  Future<void> updateAcademicProfile({
    required String uid,
    required String departmentId,
    int? enrollmentYear,
  });
}
