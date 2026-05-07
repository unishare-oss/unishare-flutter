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
  const CreatePostPublishing({required this.files});
  final List<FileUploadProgress> files;
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

@Riverpod(keepAlive: true)
class CreatePostNotifier extends _$CreatePostNotifier {
  static final _rand = Random.secure();
  static const _chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  CancellationToken? _cancellationToken;
  PostDraft? _inflight;
  Map<String, Uint8List>? _inflightFileData;

  @override
  CreatePostState build() {
    ref.onDispose(() => _cancellationToken?.cancel());
    return const CreatePostIdle();
  }

  Future<void> submit({
    required PostDraft draft,
    Map<String, Uint8List>? fileDataOverride,
  }) async {
    if (state is CreatePostUploading || state is CreatePostPublishing) return;
    // Capture locally so cancel() nulling the field doesn't affect this run.
    final token = CancellationToken();
    _cancellationToken = token;
    _inflight = draft;
    _inflightFileData = fileDataOverride;

    final filenames = draft.localMediaPaths.isEmpty
        ? <String>[]
        : draft.localMediaPaths.map((p) => p.split('/').last).toList();

    if (filenames.isEmpty) {
      state = const CreatePostPublishing(files: []);
    } else {
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
    }

    final useCase = ref.read(createPostUseCaseProvider);

    double currentOverall = 0.0;
    try {
      final results = await Connectivity().checkConnectivity();
      final isConnected = kIsWeb || !results.contains(ConnectivityResult.none);

      final result = await useCase(
        draft: draft,
        isConnected: isConnected,
        fileDataOverride: fileDataOverride,
        cancellationToken: token,
        onFileProgress: (fileIndex, fileProgress) {
          if (token.isCancelled || !ref.mounted) return;
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
            phase: fileProgress >= 1.0
                ? FileUploadPhase.done
                : FileUploadPhase.uploading,
            progress: fileProgress,
          );

          currentOverall = (fileIndex + fileProgress) / filenames.length;
          state = CreatePostUploading(
            files: updatedFiles,
            overallProgress: currentOverall,
          );
        },
        onProgress: (p) {
          if (token.isCancelled || !ref.mounted) return;
          if (p >= 1.0) {
            final current = state;
            final allDone = current is CreatePostUploading
                ? current.files
                      .map(
                        (f) => f.copyWith(
                          phase: FileUploadPhase.done,
                          progress: 1.0,
                        ),
                      )
                      .toList()
                : <FileUploadProgress>[];
            state = CreatePostPublishing(files: allDone);
          }
        },
      );

      if (token.isCancelled || !ref.mounted) return;
      state = switch (result.status) {
        DraftStatus.published => CreatePostPublished(postId: result.id),
        DraftStatus.queued => CreatePostQueued(draftId: result.id),
        _ => CreatePostError(
          message: result.errorMessage ?? 'Upload failed. Please try again.',
          draft: result,
          overallProgress: currentOverall,
        ),
      };
    } on ArgumentError catch (e) {
      if (token.isCancelled || !ref.mounted) return;
      state = CreatePostError(
        message: _toUserMessage(e),
        draft: draft,
        overallProgress: 0.0,
      );
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel &&
          !token.isCancelled &&
          ref.mounted) {
        state = CreatePostError(
          message: _toUserMessage(e),
          draft: draft,
          overallProgress: currentOverall,
        );
      }
    } catch (e) {
      if (token.isCancelled || !ref.mounted) return;
      state = CreatePostError(
        message: _toUserMessage(e),
        draft: draft,
        overallProgress: currentOverall,
      );
    }
  }

  static String _toUserMessage(Object e) {
    if (e is ArgumentError) {
      return switch (e.message.toString()) {
        'title_required' => 'Please add a title before submitting.',
        'description_required' => 'Please add a description before submitting.',
        'module_required' => 'Please add a module number before submitting.',
        _ => 'Check your inputs and try again.',
      };
    }
    if (e is DioException) {
      return switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'Request timed out. Check your connection and try again.',
        DioExceptionType.connectionError =>
          'No internet connection. Your draft has been saved.',
        _ => 'Network error. Please try again.',
      };
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> cancel() async {
    _cancellationToken?.cancel();
    // TODO: orphaned R2 files — add worker DELETE endpoint and call it
    // for each url in _inflight.uploadedUrls before removing the draft.
    final draft = _inflight;
    _inflight = null;
    _inflightFileData = null;
    _cancellationToken = null;
    state = const CreatePostIdle();
    if (draft != null) {
      await ref.read(postRepositoryProvider).removeDraft(draft.id);
    }
  }

  void reset() {
    _inflight = null;
    _inflightFileData = null;
    _cancellationToken = null;
    state = const CreatePostIdle();
  }

  Future<void> retry() async {
    final draft = _inflight;
    if (draft == null) return;
    await submit(draft: draft, fileDataOverride: _inflightFileData);
  }

  static String generateId() =>
      List.generate(20, (_) => _chars[_rand.nextInt(_chars.length)]).join();
}
