import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:unishare_mobile/features/auth/domain/usecases/sign_up_with_email.dart';

class _FakeAuthRepository implements AuthRepository {
  String? capturedName;
  String? capturedEmail;
  String? capturedUniversityId;

  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  Future<AppUser> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AppUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? universityId,
  }) async {
    capturedName = name;
    capturedEmail = email;
    capturedUniversityId = universityId;
    return AppUser(id: 'uid-su', name: name, email: email);
  }

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
  test('SignUpWithEmail delegates to repository with correct params', () async {
    final repo = _FakeAuthRepository();
    final useCase = SignUpWithEmail(repo);

    final user = await useCase(
      name: 'Alice',
      email: 'alice@example.com',
      password: 'secret123',
      universityId: 'uni-42',
    );

    expect(repo.capturedName, 'Alice');
    expect(repo.capturedEmail, 'alice@example.com');
    expect(repo.capturedUniversityId, 'uni-42');
    expect(user.id, 'uid-su');
  });
}
