import 'dart:math';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';

part 'create_post_provider.g.dart';

sealed class CreatePostState {
  const CreatePostState();
}

final class CreatePostIdle extends CreatePostState {
  const CreatePostIdle();
}

enum FileUploadPhase { queued, uploading, done }

class FileUploadProgress {
  const FileUploadProgress({
    required this.filename,
    required this.phase,
    this.progress = 0.0,
  });

  final String filename;
  final FileUploadPhase phase;
  final double progress;

  FileUploadProgress copyWith({FileUploadPhase? phase, double? progress}) =>
      FileUploadProgress(
        filename: filename,
        phase: phase ?? this.phase,
        progress: progress ?? this.progress,
      );
}

final class CreatePostUploading extends CreatePostState {
  const CreatePostUploading({
    required this.files,
    required this.overallProgress,
  });

  final List<FileUploadProgress> files;
  final double overallProgress;
}

final class CreatePostPublishing extends CreatePostState {
  const CreatePostPublishing();
}

final class CreatePostPublished extends CreatePostState {
  const CreatePostPublished({required this.postId});
  final String postId;
}

final class CreatePostQueued extends CreatePostState {
  const CreatePostQueued({required this.draftId});
  final String draftId;
}

final class CreatePostError extends CreatePostState {
  const CreatePostError({
    required this.message,
    required this.draft,
    this.overallProgress = 0.0,
  });

  final String message;
  final PostDraft draft;
  final double overallProgress;
}

@riverpod
class CreatePostNotifier extends _$CreatePostNotifier {
  static final _rand = Random.secure();
  static const _chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  CancellationToken? _cancellationToken;
  PostDraft? _inflight;

  @override
  CreatePostState build() => const CreatePostIdle();

  Future<void> submit({
    required PostDraft draft,
    Map<String, Uint8List>? fileDataOverride,
  }) async {
    _cancellationToken = CancellationToken();
    _inflight = draft;

    final filenames = draft.localMediaPaths.isEmpty
        ? <String>[]
        : draft.localMediaPaths.map((p) => p.split('/').last).toList();

    state = CreatePostUploading(
      files: filenames
          .map(
            (name) => FileUploadProgress(
              filename: name,
              phase: FileUploadPhase.queued,
            ),
          )
          .toList(),
      overallProgress: 0.0,
    );

    final useCase = ref.read(createPostUseCaseProvider);

    try {
      final results = await Connectivity().checkConnectivity();
      final isConnected = kIsWeb || !results.contains(ConnectivityResult.none);

      double currentOverall = 0.0;

      final result = await useCase(
        draft: draft,
        isConnected: isConnected,
        fileDataOverride: fileDataOverride,
        cancellationToken: _cancellationToken,
        onFileProgress: (fileIndex, fileProgress) {
          final current = state;
          if (current is! CreatePostUploading) return;

          final updatedFiles = List<FileUploadProgress>.from(current.files);
          for (var j = 0; j < fileIndex; j++) {
            if (updatedFiles[j].phase != FileUploadPhase.done) {
              updatedFiles[j] = updatedFiles[j].copyWith(
                phase: FileUploadPhase.done,
                progress: 1.0,
              );
            }
          }
          updatedFiles[fileIndex] = updatedFiles[fileIndex].copyWith(
            phase: FileUploadPhase.uploading,
            progress: fileProgress,
          );

          currentOverall = (fileIndex + fileProgress) / filenames.length;
          state = CreatePostUploading(
            files: updatedFiles,
            overallProgress: currentOverall,
          );
        },
        onProgress: (p) {
          if (p >= 1.0) state = const CreatePostPublishing();
        },
      );

      state = switch (result.status) {
        DraftStatus.published => CreatePostPublished(postId: result.id),
        DraftStatus.queued => CreatePostQueued(draftId: result.id),
        _ => CreatePostError(
          message: result.errorMessage ?? 'Unknown error',
          draft: result,
          overallProgress: currentOverall,
        ),
      };
    } on ArgumentError catch (e) {
      state = CreatePostError(
        message: e.message.toString(),
        draft: draft,
        overallProgress: 0.0,
      );
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel) {
        state = CreatePostError(
          message: e.toString(),
          draft: draft,
          overallProgress: 0.0,
        );
      }
    } catch (e) {
      state = CreatePostError(
        message: e.toString(),
        draft: draft,
        overallProgress: 0.0,
      );
    }
  }

  Future<void> cancel() async {
    _cancellationToken?.cancel();
    // TODO: orphaned R2 files — add worker DELETE endpoint and call it
    // for each url in _inflight.uploadedUrls before removing the draft.
    final draft = _inflight;
    if (draft != null) {
      await ref.read(postRepositoryProvider).removeDraft(draft.id);
    }
    _inflight = null;
    _cancellationToken = null;
    state = const CreatePostIdle();
  }

  void reset() {
    _inflight = null;
    _cancellationToken = null;
    state = const CreatePostIdle();
  }

  static String generateId() =>
      List.generate(20, (_) => _chars[_rand.nextInt(_chars.length)]).join();
}
