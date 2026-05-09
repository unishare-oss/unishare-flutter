import 'package:flutter/foundation.dart';
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

  return SavedPostFirestoreRepositoryImpl(
    firestoreDatasource: firestoreDs,
    hiveDatasource: hiveDs,
  );
}

/// Listens for the unauthenticated → authenticated transition and merges any
/// guest-accumulated saves exactly once per session. Must be initialized at
/// app startup via [ref.watch] in the root widget.
@Riverpod(keepAlive: true)
void mergeGuestSavesOnLogin(Ref ref) {
  var hasMerged = false;

  ref.listen(authStateProvider, (previous, next) {
    if (hasMerged) return;
    final wasUnauthenticated = previous?.asData?.value == null;
    final isNowAuthenticated = next.asData?.value != null;
    final isGuest = ref.read(guestModeProvider);
    if (wasUnauthenticated && isNowAuthenticated && !isGuest) {
      hasMerged = true;
      final hiveDs = ref.read(savedPostHiveDatasourceProvider);
      final guestSaves = hiveDs.readAll();
      if (guestSaves.isNotEmpty) {
        final firestoreDs = ref.read(savedPostFirestoreDatasourceProvider);
        final firestoreRepo = SavedPostFirestoreRepositoryImpl(
          firestoreDatasource: firestoreDs,
          hiveDatasource: hiveDs,
        );
        MergeGuestSaves(firestoreRepo)
            .call(guestSaves)
            .catchError((Object e) => debugPrint('mergeGuestSaves failed: $e'));
      }
    }
  });
}
