enum AuthFailureType {
  invalidCredentials,
  emailAlreadyInUse,
  networkError,
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.type, [this.message]);

  final AuthFailureType type;
  final String? message;

  String get userMessage => switch (type) {
    AuthFailureType.invalidCredentials => 'Invalid email or password',
    AuthFailureType.emailAlreadyInUse =>
      'An account with this email already exists',
    AuthFailureType.networkError => 'Check your connection and try again',
    AuthFailureType.unknown => message ?? 'Something went wrong',
  };
}
