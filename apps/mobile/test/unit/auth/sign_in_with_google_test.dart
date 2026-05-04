import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:unishare_mobile/features/auth/domain/usecases/sign_in_with_google.dart';

class _FakeAuthRepository implements AuthRepository {
  bool called = false;

  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  Future<AppUser> signInWithGoogle() async {
    called = true;
    return const AppUser(
      id: 'uid-g',
      name: 'Google User',
      email: 'g@example.com',
    );
  }

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
  test('SignInWithGoogle delegates to repository', () async {
    final repo = _FakeAuthRepository();
    final useCase = SignInWithGoogle(repo);

    final user = await useCase();

    expect(repo.called, isTrue);
    expect(user.id, 'uid-g');
    expect(user.name, 'Google User');
  });
}
