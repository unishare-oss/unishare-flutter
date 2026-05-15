import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';

part 'departments_provider.g.dart';

/// All departments, unscoped. Mostly used by admin/seed flows; user-facing
/// pickers should prefer [departmentsForUniversity].
@riverpod
Stream<List<({String id, String name})>> departments(Ref ref) {
  final datasource = ref.watch(firestoreUserDatasourceProvider);
  return datasource.getDepartments();
}

/// Departments scoped to a single university. Empty list when [universityId]
/// is null/empty. Server-side filter (no client-side over-fetch).
@riverpod
Stream<List<({String id, String name})>> departmentsForUniversity(
  Ref ref,
  String? universityId,
) {
  if (universityId == null || universityId.isEmpty) {
    return Stream.value(const []);
  }
  final ds = ref.watch(firestoreUserDatasourceProvider);
  return ds.getDepartmentsForUniversity(universityId);
}
