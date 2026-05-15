import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';

part 'departments_provider.g.dart';

@riverpod
Stream<List<({String id, String name})>> departments(Ref ref) {
  final datasource = ref.watch(firestoreUserDatasourceProvider);
  return datasource.getDepartments();
}

/// Departments scoped to a single university. Empty list when [universityId]
/// is null. Hand-written rather than generated so we can add it without
/// rerunning build_runner.
final departmentsForUniversityProvider = StreamProvider.autoDispose
    .family<List<({String id, String name})>, String?>((ref, universityId) {
      if (universityId == null || universityId.isEmpty) {
        return Stream.value(const []);
      }
      final ds = ref.watch(firestoreUserDatasourceProvider);
      return ds.getDepartmentsForUniversity(universityId);
    });
