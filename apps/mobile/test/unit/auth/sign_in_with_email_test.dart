import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:unishare_mobile/features/auth/domain/usecases/sign_in_with_email.dart';

class _FakeAuthRepository implements AuthRepository {
  String? capturedEmail;
  String? capturedPassword;

  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  Future<AppUser> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    capturedEmail = email;
    capturedPassword = password;
    return AppUser(id: 'uid-e', name: 'Email User', email: email);
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? universityId,
  }) => throw UnimplementedError();

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

void main() {
  test('SignInWithEmail delegates to repository with correct params', () async {
    final repo = _FakeAuthRepository();
    final useCase = SignInWithEmail(repo);

    final user = await useCase(email: 'test@example.com', password: 'pass123');

    expect(repo.capturedEmail, 'test@example.com');
    expect(repo.capturedPassword, 'pass123');
    expect(user.id, 'uid-e');
  });
}
