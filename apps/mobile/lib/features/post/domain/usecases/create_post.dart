import 'dart:typed_data';

import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';

class CreatePost {
  const CreatePost(this._repository);

  final PostRepository _repository;

  /// Validates [draft], saves it to the queue, then attempts to publish.
  ///
  /// Returns the draft with [DraftStatus.published] on success,
  /// [DraftStatus.queued] when offline,
  /// and throws [ArgumentError] on validation failure.
  ///
  /// [fileDataOverride] supplies in-memory bytes for each file keyed by the
  /// value used in [PostDraft.localMediaPaths] — required on web where
  /// dart:io File is unavailable. File-size enforcement is done at the widget
  /// layer before pick, so it is not repeated here.
  Future<PostDraft> call({
    required PostDraft draft,
    required bool isConnected,
    void Function(double progress)? onProgress,
    Map<String, Uint8List>? fileDataOverride,
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
        fileDataOverride: fileDataOverride,
      );
      return draft.copyWith(status: DraftStatus.published);
    } catch (_) {
      return draft.copyWith(status: DraftStatus.queued);
    }
  }
}
