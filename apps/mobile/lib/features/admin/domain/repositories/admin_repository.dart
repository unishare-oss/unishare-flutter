import 'package:unishare_mobile/features/admin/domain/entities/admin_user.dart';

/// Admin console operations. Implemented by [AdminRepositoryImpl] over a
/// Firestore datasource (reads/reference-data writes) and a Functions
/// datasource (privileged callables).
///
/// TEMPLATE: this is intentionally lean. Following the project's Clean
/// Architecture convention you may want to extract per-operation use cases
/// (see features/moderation/domain/usecases for the pattern) — left out here
/// to keep the scaffold compact.
abstract interface class AdminRepository {
  /// Live list of users. Requires the `isAdmin()` read grant in
  /// firestore.rules. Newest-naming/ordering is the datasource's concern.
  Stream<List<AdminUser>> watchUsers({int limit});

  /// Promote/demote a user via the admin-gated `setUserRole` callable.
  Future<void> setUserRole(String uid, String role);

  /// TODO(admin-ban): backend not implemented — see datasource.
  Future<void> setUserBanned(String uid, bool banned);

  /// All departments (id + name) for the admin catalog view.
  Stream<List<({String id, String name})>> watchDepartments();

  /// Create a department doc. Admin-only write (firestore.rules).
  Future<void> createDepartment({
    required String id,
    required String name,
    required String universityId,
  });

  /// Create a course under a department. Admin-only write (firestore.rules).
  Future<void> createCourse({
    required String departmentId,
    required String code,
    required String name,
    int? yearLevel,
  });
}
