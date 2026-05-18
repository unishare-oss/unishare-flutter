import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';

abstract interface class AuthRepository {
  /// Emits null when signed out, AppUser when signed in.
  Stream<AppUser?> get authStateChanges;

  Future<AppUser> signInAnonymously();

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

  Future<void> updateProfile({
    required String uid,
    required String name,
    String? bio,
    String? universityId,
    String? departmentId,
    int? enrollmentYear,
  });

  Future<void> updateAcademicProfile({
    required String uid,
    required String departmentId,
    int? enrollmentYear,
  });
}
