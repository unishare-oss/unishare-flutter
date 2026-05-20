import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';
import 'package:unishare_mobile/core/logging/app_logger.dart';

import 'package:unishare_mobile/features/post/data/datasources/ai_reindex_datasource.dart';
import 'package:unishare_mobile/features/post/data/datasources/ai_summarize_datasource.dart';
import 'package:unishare_mobile/features/post/data/datasources/feed_cache.dart';
import 'package:unishare_mobile/features/post/data/datasources/tag_whitelist_service.dart';
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
    AiSummarizeDatasource? aiSummarizeDatasource,
    TagWhitelistService? tagWhitelistService,
    AiReindexDatasource? aiReindexDatasource,
  }) : _aiSummarizeDatasource =
           aiSummarizeDatasource ?? AiSummarizeDatasource(),
       _tagWhitelistService = tagWhitelistService,
       _aiReindexDatasource = aiReindexDatasource ?? AiReindexDatasource();

  final PostFirestoreDatasource firestoreDatasource;
  final PostStorageDatasource storageDatasource;
  final Box<PostDraftModel> draftBox;
  final FeedCache feedCache;
  final Duration cacheTtl;
  final AiSummarizeDatasource _aiSummarizeDatasource;

  /// Optional — null in unit tests that don't exercise vocabulary control.
  /// When set, [triggerSummarize] passes the cached top-tags list to the
  /// worker so the model prefers reusing existing tag vocabulary.
  final TagWhitelistService? _tagWhitelistService;

  final AiReindexDatasource _aiReindexDatasource;

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
  Stream<List<Post>> watchPostsByAuthor(String authorId, {int limit = 50}) =>
      firestoreDatasource.watchPostsByAuthor(authorId, limit: limit);

  @override
  Future<int> countPostsByAuthor(String authorId) =>
      firestoreDatasource.countPostsByAuthor(authorId);

  @override
  Future<void> incrementViewCount(String postId) =>
      firestoreDatasource.incrementViewCount(postId);

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
    void Function(PostDraft)? onDraftUpdated,
    Map<String, Uint8List>? fileDataOverride,
    CancellationToken? cancellationToken,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('not_authenticated');

    // Fetch once — avoids a per-file round trip to Firebase Auth.
    final idToken = await user.getIdToken() ?? '';
    if (idToken.isEmpty) throw StateError('id_token_unavailable');

    final dioCancelToken = CancelToken();
    cancellationToken?.addCancelListener(dioCancelToken.cancel);

    var current = draft;
    final paths = draft.localMediaPaths;

    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      if (current.uploadedUrls.containsKey(path)) continue;
      if (cancellationToken?.isCancelled ?? false) return;

      // Signal the UI immediately so the row flips to "uploading" while we
      // read the file from disk and wait for the presign response.
      onFileProgress?.call(i, 0.0);

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
                idToken,
                onProgress: progressFn,
                cancelToken: dioCancelToken,
              )
            : await storageDatasource.upload(
                path,
                idToken,
                onProgress: progressFn,
                cancelToken: dioCancelToken,
              );

        final newUrls = Map<String, String>.from(current.uploadedUrls)
          ..[path] = url;
        current = current.copyWith(uploadedUrls: newUrls);
        await saveDraft(current);
        onDraftUpdated?.call(current);
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
        idToken,
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

      final supportedIndex = mediaTypes.indexWhere(
        (t) => t == 'pdf' || t == 'docx' || t == 'image',
      );
      if (supportedIndex != -1) {
        final fileUrl = mediaUrls[supportedIndex];
        final filename = fileUrl.split('/').last;
        triggerSummarize(current.id, fileUrl, filename, title: current.title);
      }
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

  @visibleForTesting
  void triggerSummarize(
    String postId,
    String fileUrl,
    String filename, {
    String title = '',
  }) {
    // Fire-and-forget: fetch the Phase A whitelist (advisory; failures
    // degrade to an empty list), then dispatch summarize and write back
    // whatever the worker returns. [title] is passed to the worker so it
    // can include it in the Vectorize search blob (PROP-0011 Phase 4a).
    Future<void> runSummarize() async {
      final existingTags = await _tagWhitelistService?.topTags() ?? const [];
      try {
        final data = await _aiSummarizeDatasource.call(
          fileUrl: fileUrl,
          filename: filename,
          existingTags: existingTags,
          postId: postId,
          title: title,
        );
        final summaryStatus = data['summaryStatus'] as String? ?? 'error';
        final summary = data['summary'] as String?;
        final extractedText = data['extractedText'] as String?;
        final extractedTextTruncated = data['extractedTextTruncated'] as bool?;
        // Defensive parse: aiTags crosses a network boundary, so don't trust
        // the runtime shape. Drop any non-string entries instead of throwing
        // on a malformed worker response (Copilot review #4).
        final aiTagsRaw = data['aiTags'];
        final aiTags = aiTagsRaw is List
            ? aiTagsRaw.whereType<String>().toList(growable: false)
            : const <String>[];
        await firestoreDatasource.updatePostSummary(
          postId,
          summary,
          summaryStatus,
          extractedText: extractedText,
          extractedTextTruncated: extractedTextTruncated,
          aiTags: aiTags,
        );
      } catch (_) {
        // Explicitly clear derived fields on retry-failure so a previously
        // successful summary's data doesn't survive next to an `error` status
        // (Copilot review #3).
        await firestoreDatasource.updatePostSummary(
          postId,
          null,
          'error',
          extractedText: null,
          extractedTextTruncated: null,
          aiTags: const [],
        );
      }
    }

    // ignore: unawaited_futures
    runSummarize();
  }

  @override
  Future<void> deletePost(String postId) async {
    final post = await firestoreDatasource.watchPost(postId).first;
    for (final url in post.mediaUrls) {
      await storageDatasource.deleteFile(url);
    }
    await storageDatasource.deleteFile(post.codeSnippetUrl);
    await firestoreDatasource.deletePost(postId);
    feedCache.invalidate();
  }

  @override
  Future<void> updatePost({
    required String postId,
    required String title,
    required String description,
    required List<String> tags,
    String? externalUrl,
    required String moduleNumber,
    required bool descriptionChanged,
    required bool titleChanged,
    required SummaryStatus? currentSummaryStatus,
  }) async {
    await firestoreDatasource.updatePost(
      postId: postId,
      title: title,
      description: description,
      tags: tags,
      externalUrl: externalUrl,
      moduleNumber: moduleNumber,
      descriptionChanged: descriptionChanged,
      currentSummaryStatus: currentSummaryStatus,
    );

    // PROP-0011 follow-up — fire-and-forget reindex when fields that feed the
    // semantic-search blob have changed. Failure is logged; the edit already
    // succeeded in Firestore so we never block the UI on a search-drift issue.
    if (titleChanged || descriptionChanged) {
      unawaited(
        _aiReindexDatasource
            .call(postId: postId, title: title, description: description)
            .catchError((Object e, StackTrace st) {
          AppLogger.error(
            'reindex_failed: postId=$postId',
            error: e,
            stackTrace: st,
          );
          return false;
        }),
      );
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
      case 'docx':
        return 'docx';
      case 'mp4':
      case 'mov':
      case 'avi':
        return 'video';
      default:
        return 'image';
    }
  }
}
