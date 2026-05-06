import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';
import 'package:unishare_mobile/features/post/data/datasources/post_firestore_datasource.dart';
import 'package:unishare_mobile/features/post/data/datasources/post_storage_datasource.dart';
import 'package:unishare_mobile/features/post/data/models/post_draft_model.dart';

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
    return draftBox.values.map((m) => m.toEntity()).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<void> publishDraft(
    PostDraft draft, {
    void Function(double progress)? onProgress,
    Map<String, Uint8List>? fileDataOverride,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('not_authenticated');

    // Step 1: start with the draft's current uploadedUrls (may be partially
    // populated from a prior attempt).
    var current = draft;
    final paths = draft.localMediaPaths;

    // Step 2: upload each file, skipping already-uploaded ones.
    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];

      // 2a. Already uploaded — skip.
      if (current.uploadedUrls.containsKey(path)) continue;

      try {
        // 2b. Upload and get download URL.
        // Use bytes override on web (path is a name, not a filesystem path).
        final progressFn = onProgress != null
            ? (fp) => onProgress((i + fp) / paths.length)
            : null;
        final overrideBytes = fileDataOverride?[path];
        final url = overrideBytes != null
            ? await storageDatasource.uploadBytes(
                overrideBytes,
                path,
                user.uid,
                onProgress: progressFn,
              )
            : await storageDatasource.upload(
                path,
                user.uid,
                onProgress: progressFn,
              );

        // 2c. Update uploadedUrls and persist so the URL survives a crash.
        final newUrls = Map<String, String>.from(current.uploadedUrls)
          ..[path] = url;
        current = current.copyWith(uploadedUrls: newUrls);
        await saveDraft(current);
      } catch (e) {
        // 2d. Persist partial progress and rethrow.
        await saveDraft(
          current.copyWith(
            status: DraftStatus.error,
            errorMessage: e.toString(),
          ),
        );
        rethrow;
      }
    }

    // Step 3: if a code snippet is present, upload it as text/plain and
    // collect the download URL.
    String? codeSnippetUrl;
    if (draft.codeSnippet != null) {
      final snippet = draft.codeSnippet!;
      final ext = snippet.language.toLowerCase();
      final filename = '${snippet.filename}.$ext';
      codeSnippetUrl = await storageDatasource.uploadText(
        snippet.content,
        user.uid,
        filename,
      );
    }

    // Step 4: derive mediaUrls in localMediaPaths order.
    final mediaUrls = paths
        .where((p) => current.uploadedUrls.containsKey(p))
        .map((p) => current.uploadedUrls[p]!)
        .toList();

    // Step 5: write to Firestore; remove draft on success.
    try {
      await firestoreDatasource.createPost(
        draft: current,
        mediaUrls: mediaUrls,
        authorName: draft.postingIdentity == PostingIdentity.anonymous
            ? ''
            : (user.displayName ?? ''),
        authorAvatar: draft.postingIdentity == PostingIdentity.anonymous
            ? ''
            : (user.photoURL ?? ''),
        codeSnippetUrl: codeSnippetUrl,
      );
      // Step 6: remove from queue on success.
      await removeDraft(draft.id);
    } catch (e) {
      // Step 7: leave draft in queue with queued status so SyncDraftQueue
      // can retry.
      await saveDraft(
        current.copyWith(
          uploadedUrls: current.uploadedUrls,
          status: DraftStatus.queued,
        ),
      );
      rethrow;
    }
  }
}
