import 'dart:typed_data';

import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';

class CreatePost {
  const CreatePost(this._repository);

  final PostRepository _repository;

  Future<PostDraft> call({
    required PostDraft draft,
    required bool isConnected,
    void Function(double progress)? onProgress,
    void Function(int fileIndex, double fileProgress)? onFileProgress,
    Map<String, Uint8List>? fileDataOverride,
    CancellationToken? cancellationToken,
  }) async {
    if (draft.title.trim().isEmpty) throw ArgumentError('title_required');
    if (draft.description.trim().isEmpty) {
      throw ArgumentError('description_required');
    }
    if (draft.moduleNumber.trim().isEmpty) {
      throw ArgumentError('module_required');
    }

    await _repository.saveDraft(draft);

    if (!isConnected) return draft.copyWith(status: DraftStatus.queued);

    try {
      await _repository.publishDraft(
        draft,
        onProgress: onProgress,
        onFileProgress: onFileProgress,
        fileDataOverride: fileDataOverride,
        cancellationToken: cancellationToken,
      );
      if (cancellationToken?.isCancelled == true) {
        return draft.copyWith(status: DraftStatus.queued);
      }
      return draft.copyWith(status: DraftStatus.published);
    } catch (_) {
      return draft.copyWith(status: DraftStatus.queued);
    }
  }
}
