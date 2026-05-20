// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/saved/domain/entities/saved_post.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post_snapshot.dart';

abstract interface class SavedPostRepository {
  /// Emits the full saved list ordered by savedAt descending.
  /// Re-emits on every change (Firestore snapshots or Hive box change).
  Stream<List<SavedPost>> watchSavedPosts();

  /// Saves the post. Snapshot is captured from the Post entity at call time.
  /// If the post is already saved, this is a no-op (idempotent).
  Future<void> savePost(String postId, SavedPostSnapshot snapshot);

  /// Removes the post from the saved list.
  /// If the post is not saved, this is a no-op (idempotent).
  Future<void> unsavePost(String postId);

  /// Emits true when [postId] is in the saved list; false otherwise.
  Stream<bool> isPostSaved(String postId);

  /// Batch-writes [guestSaves] into the backing store using merge semantics.
  /// On the Hive implementation this is a no-op — returns immediately.
  /// On the Firestore implementation this writes all entries then clears the
  /// Hive box via the injected [SavedPostHiveDatasource].
  Future<void> mergeFrom(List<SavedPost> guestSaves);
}
