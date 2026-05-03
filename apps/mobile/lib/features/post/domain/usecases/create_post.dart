import 'dart:io';

import '../entities/post_draft.dart';
import '../repositories/post_repository.dart';

class CreatePost {
  const CreatePost(this._repository);

  final PostRepository _repository;

  static const _maxBytes = 10 * 1024 * 1024; // 10 MB
  static const _allowedExtensions = {
    'jpg', 'jpeg', 'png', 'webp', 'pdf',
  };

  /// Validates [draft], saves it to the queue, then attempts to publish.
  ///
  /// Returns the draft with [DraftStatus.published] on success,
  /// [DraftStatus.queued] when offline or on a transient failure,
  /// and throws [ArgumentError] on validation failure.
  Future<PostDraft> call({
    required PostDraft draft,
    required bool isConnected,
    void Function(double progress)? onProgress,
  }) async {
    if (draft.title.trim().isEmpty) {
      throw ArgumentError('title_required');
    }

    for (final path in draft.localMediaPaths) {
      final file = File(path);
      final size = await file.length();
      if (size > _maxBytes) throw ArgumentError('invalid_media');
      final ext = path.split('.').last.toLowerCase();
      if (!_allowedExtensions.contains(ext)) throw ArgumentError('invalid_media');
    }

    await _repository.saveDraft(draft);

    if (!isConnected) {
      return draft.copyWith(status: DraftStatus.queued);
    }

    try {
      await _repository.publishDraft(draft, onProgress: onProgress);
      return draft.copyWith(status: DraftStatus.published);
    } catch (_) {
      return draft.copyWith(status: DraftStatus.queued);
    }
  }
}
