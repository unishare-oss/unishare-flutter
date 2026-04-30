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
  }) async {
    await _users.doc(uid).set({
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'universityId': universityId,
      'role': 'student',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAcademicProfile({
    required String uid,
    required String departmentId,
    int? enrollmentYear,
  }) async {
    await _users.doc(uid).update({
      'departmentId': departmentId,
      'enrollmentYear': enrollmentYear,
    });
  }

  Future<void> writeConsentGivenAt(String uid) async {
    await _users.doc(uid).update({
      'consentGivenAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<({String id, String name})>> getUniversities() {
    return _universities.snapshots().map(
      (snap) => snap.docs
          .map((doc) => (id: doc.id, name: doc.data()['name'] as String? ?? ''))
          .toList(),
    );
  }

  Stream<List<({String id, String name})>> getDepartments() {
    return _departments.snapshots().map(
      (snap) => snap.docs
          .map((doc) => (id: doc.id, name: doc.data()['name'] as String? ?? ''))
          .toList(),
    );
  }
}
