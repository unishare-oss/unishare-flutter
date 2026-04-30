class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.universityId,
    this.departmentId,
    this.enrollmentYear,
    this.role = 'student',
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String? photoUrl;
  final String? universityId;
  final String? departmentId;
  final int? enrollmentYear;
}
