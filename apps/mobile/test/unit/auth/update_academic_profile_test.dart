import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:unishare_mobile/features/auth/domain/usecases/update_academic_profile.dart';

class _FakeAuthRepository implements AuthRepository {
  String? capturedUid;
  String? capturedDepartmentId;
  int? capturedEnrollmentYear;

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
  }) async {
    capturedUid = uid;
    capturedDepartmentId = departmentId;
    capturedEnrollmentYear = enrollmentYear;
  }
}

void main() {
  test(
    'UpdateAcademicProfile delegates to repository with correct params',
    () async {
      final repo = _FakeAuthRepository();
      final useCase = UpdateAcademicProfile(repo);

      await useCase(
        uid: 'uid-abc',
        departmentId: 'dept-cs',
        enrollmentYear: 2023,
      );

      expect(repo.capturedUid, 'uid-abc');
      expect(repo.capturedDepartmentId, 'dept-cs');
      expect(repo.capturedEnrollmentYear, 2023);
    },
  );

  test('UpdateAcademicProfile works with null enrollmentYear', () async {
    final repo = _FakeAuthRepository();
    final useCase = UpdateAcademicProfile(repo);

    await useCase(uid: 'uid-abc', departmentId: 'dept-math');

    expect(repo.capturedEnrollmentYear, isNull);
  });
}
