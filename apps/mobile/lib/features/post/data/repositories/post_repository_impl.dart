import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/post.dart';
import '../../domain/entities/post_draft.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_firestore_datasource.dart';
import '../datasources/post_storage_datasource.dart';
import '../models/post_draft_model.dart';

class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl({
    required this.firestoreDatasource,
    required this.storageDatasource,
    required this.draftBox,
  });

  final PostFirestoreDatasource firestoreDatasource;
  final PostStorageDatasource storageDatasource;
  final Box<PostDraftModel> draftBox;

  @override
  Stream<List<Post>> watchFeed({int limit = 20}) {
    // Implemented by the feed feature — not in scope for SPEC-0004.
    throw UnimplementedError('watchFeed not implemented in post write path');
  }

  @override
  Future<void> saveDraft(PostDraft draft) async {
    await draftBox.put(draft.id, PostDraftModel.fromEntity(draft));
  }

  @override
  Future<void> removeDraft(String draftId) async {
    await draftBox.delete(draftId);
  }

  @override
  Future<List<PostDraft>> loadDraftQueue() async {
    return draftBox.values
        .map((m) => m.toEntity())
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<void> publishDraft(
    PostDraft draft, {
    void Function(double progress)? onProgress,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('not_authenticated');

    // Step 1: start with the draft's current uploadedUrls (may be partially populated).
    var current = draft;
    final paths = draft.localMediaPaths;

    // Step 2: upload each file, skipping already-uploaded ones.
    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];

      // 2a. Already uploaded — skip.
      if (current.uploadedUrls.containsKey(path)) continue;

      try {
        // 2b. Upload and get download URL.
        final url = await storageDatasource.upload(
          path,
          user.uid,
          onProgress: onProgress != null
              ? (fp) => onProgress((i + fp) / paths.length)
              : null,
        );

        // 2c. Update uploadedUrls and persist so the URL survives a crash.
        final newUrls = Map<String, String>.from(current.uploadedUrls)..[path] = url;
        current = current.copyWith(uploadedUrls: newUrls);
        await saveDraft(current);
      } catch (e) {
        // 2d. Persist partial progress and rethrow.
        await saveDraft(current.copyWith(
          status: DraftStatus.error,
          errorMessage: e.toString(),
        ));
        rethrow;
      }
    }

    // Step 3: derive mediaUrls in localMediaPaths order.
    final mediaUrls = paths
        .where((p) => current.uploadedUrls.containsKey(p))
        .map((p) => current.uploadedUrls[p]!)
        .toList();

    // Step 4 & 5: write to Firestore, remove draft on success.
    try {
      await firestoreDatasource.createPost(
        draft: current,
        mediaUrls: mediaUrls,
        authorName: user.displayName ?? '',
        authorAvatar: user.photoURL ?? '',
      );
      // Step 5: remove from queue on success.
      await removeDraft(draft.id);
    } catch (e) {
      // Step 6: leave draft in queue as queued so SyncDraftQueue can retry.
      await saveDraft(current.copyWith(
        uploadedUrls: current.uploadedUrls,
        status: DraftStatus.queued,
      ));
      rethrow;
    }
  }
}
