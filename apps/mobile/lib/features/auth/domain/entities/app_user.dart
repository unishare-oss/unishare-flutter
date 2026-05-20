class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.universityId,
    this.departmentId,
    this.enrollmentYear,
    this.bio,
    this.role = 'student',
    this.providerIds = const <String>[],
    this.isAnonymous = false,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String? photoUrl;
  final String? universityId;
  final String? departmentId;
  final int? enrollmentYear;
  final String? bio;

  /// Firebase Auth provider IDs linked to this account.
  /// e.g. `google.com`, `password`, `apple.com`. Empty when unknown.
  final List<String> providerIds;

  final bool isAnonymous;
}
