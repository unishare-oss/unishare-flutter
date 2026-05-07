import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/post/data/datasources/course_firestore_datasource.dart';

part 'course_reference_provider.g.dart';

@Riverpod(keepAlive: true)
CourseFirestoreDatasource courseFirestoreDatasource(Ref ref) =>
    CourseFirestoreDatasource();

@Riverpod(keepAlive: true)
Future<List<({String id, String name})>> departmentsForUniversity(
  Ref ref,
  String universityId,
) => ref.read(courseFirestoreDatasourceProvider).getDepartments(universityId);

@Riverpod(keepAlive: true)
Future<List<({String id, String name})>> courses(
  Ref ref,
  String deptId,
  int year,
) => ref.read(courseFirestoreDatasourceProvider).getCourses(deptId, year);
