// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/saved/domain/entities/saved_post.dart';
import 'package:unishare_mobile/features/saved/domain/repositories/saved_post_repository.dart';

class MergeGuestSaves {
  const MergeGuestSaves(this._firestoreRepository);
  final SavedPostRepository _firestoreRepository;

  /// Merges [guestSaves] into the Firestore-backed repository.
  /// If [guestSaves] is empty, returns immediately without any writes.
  /// On success the Firestore repository impl clears the Hive box.
  /// On failure the exception propagates to the caller; Hive is not cleared.
  Future<void> call(List<SavedPost> guestSaves) {
    if (guestSaves.isEmpty) return Future.value();
    return _firestoreRepository.mergeFrom(guestSaves);
  }
}
