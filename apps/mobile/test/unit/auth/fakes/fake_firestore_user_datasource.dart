import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/auth/data/datasources/firestore_user_datasource.dart';
import 'package:unishare_mobile/features/auth/data/models/app_user_model.dart';

// ---------------------------------------------------------------------------
// Minimal FirebaseFirestore stub — never touches the SDK
// ---------------------------------------------------------------------------

class _StubFirestore extends Fake implements FirebaseFirestore {}

// ---------------------------------------------------------------------------
// In-memory fake for [FirestoreUserDatasource].
// ---------------------------------------------------------------------------

class FakeFirestoreUserDatasource extends FirestoreUserDatasource {
  FakeFirestoreUserDatasource() : super(firestore: _StubFirestore());

  final Map<String, AppUserModel> storedUsers = {};
  final Set<String> consentWrittenForUids = {};
  int createUserCallCount = 0;

  @override
  Future<AppUserModel?> getUser(String uid) async => storedUsers[uid];

  @override
  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
    String? universityId,
  }) async {
    createUserCallCount++;
    storedUsers[uid] = AppUserModel(
      id: uid,
      name: name,
      email: email,
      photoUrl: photoUrl,
      universityId: universityId,
    );
  }

  @override
  Future<void> updateAcademicProfile({
    required String uid,
    required String departmentId,
    int? enrollmentYear,
  }) async {
    final existing = storedUsers[uid];
    if (existing != null) {
      storedUsers[uid] = existing.copyWith(
        departmentId: departmentId,
        enrollmentYear: enrollmentYear,
      );
    }
  }

  @override
  Future<void> writeConsentGivenAt(String uid) async {
    consentWrittenForUids.add(uid);
  }

  @override
  Stream<List<({String id, String name})>> getUniversities() =>
      Stream.value([]);

  @override
  Stream<List<({String id, String name})>> getDepartments() => Stream.value([]);
}
