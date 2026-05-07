import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/saved/data/datasources/saved_post_firestore_datasource.dart';
import 'package:unishare_mobile/features/saved/data/datasources/saved_post_hive_datasource.dart';
import 'package:unishare_mobile/features/saved/data/repositories/saved_post_firestore_repository_impl.dart';
import 'package:unishare_mobile/features/saved/data/repositories/saved_post_hive_repository_impl.dart';
import 'package:unishare_mobile/features/saved/domain/repositories/saved_post_repository.dart';
import 'package:unishare_mobile/features/saved/domain/usecases/merge_guest_saves.dart';

part 'saved_post_repository_provider.g.dart';

@Riverpod(keepAlive: true)
SavedPostHiveDatasource savedPostHiveDatasource(Ref ref) =>
    SavedPostHiveDatasource();

@Riverpod(keepAlive: true)
SavedPostFirestoreDatasource savedPostFirestoreDatasource(Ref ref) =>
    SavedPostFirestoreDatasource();

@Riverpod(keepAlive: true)
SavedPostRepository savedPostRepository(Ref ref) {
  final authAsync = ref.watch(authStateProvider);
  final isGuest = ref.watch(guestModeProvider);
  final hiveDs = ref.watch(savedPostHiveDatasourceProvider);
  final firestoreDs = ref.watch(savedPostFirestoreDatasourceProvider);

  final isAuthenticated = authAsync.asData?.value != null;

  if (!isAuthenticated || isGuest) {
    return SavedPostHiveRepositoryImpl(hiveDs);
  }

  // Authenticated — trigger merge from any guest saves that accumulated.
  final guestSaves = hiveDs.readAll();
  if (guestSaves.isNotEmpty) {
    final firestoreRepo = SavedPostFirestoreRepositoryImpl(
      firestoreDatasource: firestoreDs,
      hiveDatasource: hiveDs,
    );
    MergeGuestSaves(firestoreRepo).call(guestSaves).ignore();
  }

  return SavedPostFirestoreRepositoryImpl(
    firestoreDatasource: firestoreDs,
    hiveDatasource: hiveDs,
  );
}
