import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/admin/data/datasources/admin_firestore_datasource.dart';
import 'package:unishare_mobile/features/admin/data/datasources/admin_functions_datasource.dart';
import 'package:unishare_mobile/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:unishare_mobile/features/admin/domain/entities/admin_user.dart';
import 'package:unishare_mobile/features/admin/domain/repositories/admin_repository.dart';

part 'admin_providers.g.dart';

@Riverpod(keepAlive: true)
AdminFirestoreDatasource adminFirestoreDatasource(Ref ref) =>
    AdminFirestoreDatasource();

@Riverpod(keepAlive: true)
AdminFunctionsDatasource adminFunctionsDatasource(Ref ref) =>
    AdminFunctionsDatasource();

@Riverpod(keepAlive: true)
AdminRepository adminRepository(Ref ref) => AdminRepositoryImpl(
  firestore: ref.watch(adminFirestoreDatasourceProvider),
  functions: ref.watch(adminFunctionsDatasourceProvider),
);

/// Live users list for the admin console.
@riverpod
Stream<List<AdminUser>> adminUsers(Ref ref) =>
    ref.watch(adminRepositoryProvider).watchUsers();

/// All departments for the admin catalog.
@riverpod
Stream<List<({String id, String name})>> adminDepartments(Ref ref) =>
    ref.watch(adminRepositoryProvider).watchDepartments();

/// Imperative user actions (promote/demote, ban). Exposes an
/// `AsyncValue<void>` the screen can watch for loading/error feedback.
@riverpod
class AdminUserActions extends _$AdminUserActions {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> setRole(String uid, String role) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).setUserRole(uid, role),
    );
  }

  /// TODO(admin-ban): currently throws (no backend). The screen catches it and
  /// shows a "not implemented" message.
  Future<void> setBanned(String uid, bool banned) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).setUserBanned(uid, banned),
    );
  }
}

/// Imperative department/course creation actions.
@riverpod
class AdminCatalogActions extends _$AdminCatalogActions {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> createDepartment({
    required String id,
    required String name,
    required String universityId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(adminRepositoryProvider)
          .createDepartment(id: id, name: name, universityId: universityId),
    );
  }

  Future<void> createCourse({
    required String departmentId,
    required String code,
    required String name,
    int? yearLevel,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(adminRepositoryProvider)
          .createCourse(
            departmentId: departmentId,
            code: code,
            name: name,
            yearLevel: yearLevel,
          ),
    );
  }
}
