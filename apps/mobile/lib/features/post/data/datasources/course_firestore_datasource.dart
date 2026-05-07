import 'package:cloud_firestore/cloud_firestore.dart';

class CourseFirestoreDatasource {
  CourseFirestoreDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<({String id, String name})>> getDepartments(
    String universityId,
  ) async {
    Query<Map<String, dynamic>> query = _firestore.collection('departments');
    if (universityId.isNotEmpty) {
      query = query.where('universityId', isEqualTo: universityId);
    }
    final snap = await query.get();
    return snap.docs
        .map((doc) => (id: doc.id, name: doc.data()['name'] as String? ?? ''))
        .toList();
  }

  Future<List<({String id, String name})>> getCourses(
    String deptId,
    int year,
  ) async {
    final snap = await _firestore
        .collection('departments')
        .doc(deptId)
        .collection('courses')
        .where('yearLevel', isEqualTo: year)
        .get();
    return snap.docs
        .map((doc) => (id: doc.id, name: doc.data()['name'] as String? ?? ''))
        .toList();
  }
}
