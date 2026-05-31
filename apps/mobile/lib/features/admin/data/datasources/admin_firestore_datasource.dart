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

  Stream<List<({String id, String name})>> watchCourses(
    String deptId,
    int year,
  ) {
    // Sort by name client-side rather than `.orderBy('name')`: combining an
    // equality filter (`yearLevel`) with an orderBy on a different field would
    // require a composite index. Course subcollections are small, so sorting in
    // Dart is cheap — and it matches the non-admin course datasource, which
    // also queries `yearLevel` with no server-side ordering.
    return _db
        .collection('departments')
        .doc(deptId)
        .collection('courses')
        .where('yearLevel', isEqualTo: year)
        .snapshots()
        .map((snap) {
          final courses = snap.docs
              .map((d) => (id: d.id, name: d.data()['name'] as String? ?? d.id))
              .toList();
          courses.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          return courses;
        });
  }

  Future<void> updateDepartment(String id, String name) {
    return _db.collection('departments').doc(id).update({'name': name});
  }

  Future<void> deleteDepartment(String id) {
    // TODO: cascade-delete courses subcollection via a Cloud Function or
    // batch write to avoid orphaned course docs.
    return _db.collection('departments').doc(id).delete();
  }

  Future<void> updateCourse(
    String deptId,
    String courseId,
    String name,
    int? yearLevel,
  ) {
    return _db
        .collection('departments')
        .doc(deptId)
        .collection('courses')
        .doc(courseId)
        .update({'name': name, 'yearLevel': yearLevel});
  }

  Future<void> deleteCourse(String deptId, String courseId) {
    return _db
        .collection('departments')
        .doc(deptId)
        .collection('courses')
        .doc(courseId)
        .delete();
  }
}
