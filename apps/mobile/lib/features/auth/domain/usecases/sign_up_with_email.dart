import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignUpWithEmail {
  const SignUpWithEmail(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String name,
    required String email,
    required String password,
    String? universityId,
  }) => _repository.signUpWithEmail(
    name: name,
    email: email,
    password: password,
    universityId: universityId,
  );
}
