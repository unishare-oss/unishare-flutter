import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_repository_provider.dart';

part 'universities_provider.g.dart';

@riverpod
Stream<List<({String id, String name})>> universities(Ref ref) {
  final datasource = ref.watch(firestoreUserDatasourceProvider);
  return datasource.getUniversities();
}
