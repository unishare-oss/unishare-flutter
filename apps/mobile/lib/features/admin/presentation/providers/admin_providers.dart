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

/// Imperative user actions (promote/demote, ban).
///
/// These methods **return** their [AsyncValue] result so the calling screen
/// can react to success/failure directly. The screen must NOT read this
/// provider's `state` after awaiting — the notifier auto-disposes once the
/// screen stops listening (it only `ref.read`s the notifier), so a late
/// `state =` write would throw "used after dispose". We guard every post-await
/// write with `ref.mounted`.
@riverpod
class AdminUserActions extends _$AdminUserActions {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<AsyncValue<void>> setRole(String uid, String role) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).setUserRole(uid, role),
    );
    if (ref.mounted) state = result;
    return result;
  }

  /// TODO(admin-ban): currently surfaces an error (no backend) — see datasource.
  Future<AsyncValue<void>> setBanned(String uid, bool banned) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).setUserBanned(uid, banned),
    );
    if (ref.mounted) state = result;
    return result;
  }
}

/// Imperative department/course creation actions. Same return-result +
/// mounted-guard contract as [AdminUserActions].
@riverpod
class AdminCatalogActions extends _$AdminCatalogActions {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<AsyncValue<void>> createDepartment({
    required String id,
    required String name,
    required String universityId,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(adminRepositoryProvider)
          .createDepartment(id: id, name: name, universityId: universityId),
    );
    if (ref.mounted) state = result;
    return result;
  }

  Future<AsyncValue<void>> createCourse({
    required String departmentId,
    required String code,
    required String name,
    int? yearLevel,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(adminRepositoryProvider)
          .createCourse(
            departmentId: departmentId,
            code: code,
            name: name,
            yearLevel: yearLevel,
          ),
    );
    if (ref.mounted) state = result;
    return result;
  }
}
