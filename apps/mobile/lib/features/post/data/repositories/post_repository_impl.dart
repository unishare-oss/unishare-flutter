import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';

import 'package:unishare_mobile/features/post/data/datasources/feed_cache.dart';
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
    required this.feedCache,
    this.cacheTtl = const Duration(minutes: 5),
  });

  final PostFirestoreDatasource firestoreDatasource;
  final PostStorageDatasource storageDatasource;
  final Box<PostDraftModel> draftBox;
  final FeedCache feedCache;
  final Duration cacheTtl;

  @override
  Stream<List<Post>> watchFeed({int limit = 20}) async* {
    if (feedCache.isValid(cacheTtl)) {
      yield feedCache.posts;
    }
    await for (final posts in firestoreDatasource.watchFeed(limit: limit)) {
      feedCache.update(posts);
      yield posts;
    }
  }

  @override
  Stream<Post> watchPost(String postId) =>
      firestoreDatasource.watchPost(postId);

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
    void Function(int fileIndex, double fileProgress)? onFileProgress,
    Map<String, Uint8List>? fileDataOverride,
    CancellationToken? cancellationToken,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('not_authenticated');

    final dioCancelToken = CancelToken();
    cancellationToken?.addCancelListener(dioCancelToken.cancel);

    var current = draft;
    final paths = draft.localMediaPaths;

    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      if (current.uploadedUrls.containsKey(path)) continue;
      if (cancellationToken?.isCancelled ?? false) return;

      try {
        void progressFn(double fp) {
          onFileProgress?.call(i, fp);
          onProgress?.call((i + fp) / paths.length);
        }

        final overrideBytes = fileDataOverride?[path];
        final url = overrideBytes != null
            ? await storageDatasource.uploadBytes(
                overrideBytes,
                path,
                user.uid,
                onProgress: progressFn,
                cancelToken: dioCancelToken,
              )
            : await storageDatasource.upload(
                path,
                user.uid,
                onProgress: progressFn,
                cancelToken: dioCancelToken,
              );

        final newUrls = Map<String, String>.from(current.uploadedUrls)
          ..[path] = url;
        current = current.copyWith(uploadedUrls: newUrls);
        await saveDraft(current);
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) return;
        await saveDraft(
          current.copyWith(
            status: DraftStatus.error,
            errorMessage: e.toString(),
          ),
        );
        rethrow;
      } catch (e) {
        await saveDraft(
          current.copyWith(
            status: DraftStatus.error,
            errorMessage: e.toString(),
          ),
        );
        rethrow;
      }
    }

    if (cancellationToken?.isCancelled ?? false) return;

    String? codeSnippetUrl;
    if (draft.codeSnippet != null) {
      final snippet = draft.codeSnippet!;
      final ext = snippet.language.toLowerCase();
      final filename = '${snippet.filename}.$ext';
      codeSnippetUrl = await storageDatasource.uploadText(
        snippet.content,
        user.uid,
        filename,
        cancelToken: dioCancelToken,
      );
    }

    final mediaUrls = paths
        .where((p) => current.uploadedUrls.containsKey(p))
        .map((p) => current.uploadedUrls[p]!)
        .toList();

    final mediaTypes = paths
        .where((p) => current.uploadedUrls.containsKey(p))
        .map(_mediaTypeFromPath)
        .toList();

    try {
      await firestoreDatasource.createPost(
        draft: current,
        mediaUrls: mediaUrls,
        mediaTypes: mediaTypes,
        authorName: draft.postingIdentity == PostingIdentity.anonymous
            ? ''
            : (user.displayName ?? ''),
        authorAvatar: draft.postingIdentity == PostingIdentity.anonymous
            ? ''
            : (user.photoURL ?? ''),
        codeSnippetUrl: codeSnippetUrl,
      );
      feedCache.invalidate();
      await removeDraft(draft.id);
    } catch (e) {
      await saveDraft(
        current.copyWith(
          uploadedUrls: current.uploadedUrls,
          status: DraftStatus.queued,
        ),
      );
      rethrow;
    }
  }

  static String _mediaTypeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return 'image';
      case 'pdf':
        return 'pdf';
      case 'mp4':
      case 'mov':
      case 'avi':
        return 'video';
      default:
        return 'image';
    }
  }
}
