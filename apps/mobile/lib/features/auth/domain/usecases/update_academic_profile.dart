import '../repositories/auth_repository.dart';

class UpdateAcademicProfile {
  const UpdateAcademicProfile(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String uid,
    required String departmentId,
    int? enrollmentYear,
  }) => _repository.updateAcademicProfile(
    uid: uid,
    departmentId: departmentId,
    enrollmentYear: enrollmentYear,
  );
}
