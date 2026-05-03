import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user_model.dart';

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
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (universityId != null) 'universityId': universityId,
      'role': 'student',
      'createdAt': FieldValue.serverTimestamp(),
      if (withConsent) 'consentGivenAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAcademicProfile({
    required String uid,
    required String departmentId,
    int? enrollmentYear,
  }) async {
    await _users.doc(uid).update({
      'departmentId': departmentId,
      if (enrollmentYear != null) 'enrollmentYear': enrollmentYear,
    });
  }

  Stream<List<({String id, String name})>> getUniversities() {
    return Stream.fromFuture(
      _universities.get().then(
        (snap) => snap.docs
            .map((doc) => (id: doc.id, name: doc.data()['name'] as String? ?? ''))
            .toList(),
      ),
    );
  }

  Stream<List<({String id, String name})>> getDepartments() {
    return Stream.fromFuture(
      _departments.get().then(
        (snap) => snap.docs
            .map((doc) => (id: doc.id, name: doc.data()['name'] as String? ?? ''))
            .toList(),
      ),
    );
  }
}
