import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unishare_mobile/features/admin/domain/entities/admin_user.dart';

/// Firestore reads/writes for the admin console.
///
/// - Reading `users` relies on the `isAdmin()` grant added to the users read
///   rule. Non-admins get permission-denied (the stream errors), which the
///   screens surface in their error state.
/// - Department/course writes rely on the `isAdmin()` write grant on
///   universities/departments/courses.
class AdminFirestoreDatasource {
  AdminFirestoreDatasource({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<AdminUser>> watchUsers({int limit = 100}) {
    // TEMPLATE: no pagination/search yet. For real use, add startAfter cursor
    // paging and a name/email query — Firestore can't substring-search, so a
    // common approach is a lowercased `searchKey` field + range query, or an
    // external index (Algolia/Typesense) via a Cloud Function.
    return _db
        .collection('users')
        .orderBy('name')
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) {
                final data = doc.data();
                return AdminUser(
                  id: doc.id,
                  name: data['name'] as String? ?? '',
                  email: data['email'] as String? ?? '',
                  role: data['role'] as String? ?? 'student',
                  photoUrl: data['photoUrl'] as String?,
                  banned: data['banned'] as bool? ?? false,
                );
              })
              .toList(growable: false),
        );
  }

  Stream<List<({String id, String name})>> watchDepartments() {
    return _db
        .collection('departments')
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => (id: d.id, name: d.data()['name'] as String? ?? d.id))
              .toList(growable: false),
        );
  }

  Future<void> createDepartment({
    required String id,
    required String name,
    required String universityId,
  }) {
    // Mirrors the seed schema: departments/{id} = { name, universityId }.
    // `set` (not merge) — creating a fresh department.
    return _db.collection('departments').doc(id).set({
      'name': name,
      'universityId': universityId,
    });
  }

  Future<void> createCourse({
    required String departmentId,
    required String code,
    required String name,
    int? yearLevel,
  }) {
    // Mirrors the seed schema: departments/{id}/courses/{code} =
    // { code, name, yearLevel? }.
    return _db
        .collection('departments')
        .doc(departmentId)
        .collection('courses')
        .doc(code)
        .set({'code': code, 'name': name, 'yearLevel': ?yearLevel});
  }
}
