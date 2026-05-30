import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unishare_mobile/features/auth/data/models/app_user_model.dart';

class FirestoreUserDatasource {
  FirestoreUserDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _universities =>
      _firestore.collection('universities');

  CollectionReference<Map<String, dynamic>> get _departments =>
      _firestore.collection('departments');

  Future<AppUserModel?> getUser(String uid) async {
    final ref = _users.doc(uid);
    final doc = await ref.get();
    if (!doc.exists) return null;
    return AppUserModel.fromFirestore(doc);
  }

  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
    String? universityId,
    bool withConsent = false,
  }) async {
    await _users.doc(uid).set({
      'name': name,
      'email': email,
      'photoUrl': ?photoUrl,
      'universityId': ?universityId,
      'role': 'student',
      'createdAt': FieldValue.serverTimestamp(),
      if (withConsent) 'consentGivenAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    String? bio,
    String? universityId,
    String? departmentId,
    int? enrollmentYear,
  }) async {
    // Write nulls explicitly so users can *clear* a field — e.g., switching
    // university to one we haven't seeded should also clear the dept.
    // Firestore writes `null` (rather than omitting the field) for these.
    await _users.doc(uid).update({
      'name': name,
      'bio': bio,
      'universityId': universityId,
      'departmentId': departmentId,
      'enrollmentYear': enrollmentYear,
    });
  }

  Future<void> updateAcademicProfile({
    required String uid,
    required String departmentId,
    int? enrollmentYear,
  }) async {
    // Use set+merge so this works for anonymous (guest) users who may not yet
    // have a users/{uid} document. A plain update() throws NOT_FOUND in that case.
    await _users.doc(uid).set(
      {'departmentId': departmentId, 'enrollmentYear': ?enrollmentYear},
      SetOptions(merge: true),
    );
  }

  Stream<List<({String id, String name})>> getUniversities() {
    return Stream.fromFuture(
      _universities.get().then(
        (snap) => snap.docs
            .map(
              (doc) => (id: doc.id, name: doc.data()['name'] as String? ?? ''),
            )
            .toList(),
      ),
    );
  }

  Stream<List<({String id, String name})>> getDepartments() {
    return Stream.fromFuture(
      _departments.get().then(
        (snap) => snap.docs
            .map(
              (doc) => (id: doc.id, name: doc.data()['name'] as String? ?? ''),
            )
            .toList(),
      ),
    );
  }

  /// Returns only departments belonging to the given university.
  /// Server-side filter (avoids streaming the full department list).
  Stream<List<({String id, String name})>> getDepartmentsForUniversity(
    String universityId,
  ) {
    return Stream.fromFuture(
      _departments
          .where('universityId', isEqualTo: universityId)
          .get()
          .then(
            (snap) => snap.docs
                .map(
                  (doc) =>
                      (id: doc.id, name: doc.data()['name'] as String? ?? ''),
                )
                .toList(),
          ),
    );
  }
}
