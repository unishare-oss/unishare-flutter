import 'package:unishare_mobile/features/admin/data/datasources/admin_firestore_datasource.dart';
import 'package:unishare_mobile/features/admin/data/datasources/admin_functions_datasource.dart';
import 'package:unishare_mobile/features/admin/domain/entities/admin_user.dart';
import 'package:unishare_mobile/features/admin/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl({
    required AdminFirestoreDatasource firestore,
    required AdminFunctionsDatasource functions,
  }) : _firestore = firestore,
       _functions = functions;

  final AdminFirestoreDatasource _firestore;
  final AdminFunctionsDatasource _functions;

  @override
  Stream<List<AdminUser>> watchUsers({int limit = 100}) =>
      _firestore.watchUsers(limit: limit);

  @override
  Future<void> setUserRole(String uid, String role) =>
      _functions.setUserRole(uid, role);

  @override
  Future<void> setUserBanned(String uid, bool banned) =>
      _functions.setUserBanned(uid, banned);

  @override
  Stream<List<({String id, String name})>> watchDepartments() =>
      _firestore.watchDepartments();

  @override
  Future<void> createDepartment({
    required String id,
    required String name,
    required String universityId,
  }) => _firestore.createDepartment(
    id: id,
    name: name,
    universityId: universityId,
  );

  @override
  Future<void> createCourse({
    required String departmentId,
    required String code,
    required String name,
    int? yearLevel,
  }) => _firestore.createCourse(
    departmentId: departmentId,
    code: code,
    name: name,
    yearLevel: yearLevel,
  );
}
