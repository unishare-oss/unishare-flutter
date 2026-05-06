import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';

class SyncDraftQueue {
  const SyncDraftQueue(this._repository);

  final PostRepository _repository;

  /// Loads all queued drafts and attempts to publish each in createdAt order.
  /// Emits each draft's updated [PostDraft] as it transitions.
  /// Stops on the first unrecoverable error to preserve ordering.
  Stream<PostDraft> call() async* {
    final drafts = await _repository.loadDraftQueue();

    for (final draft in drafts) {
      if (draft.status == DraftStatus.published) continue;

      try {
        await _repository.publishDraft(draft);
        yield draft.copyWith(status: DraftStatus.published);
      } catch (e) {
        yield draft.copyWith(
          status: DraftStatus.error,
          errorMessage: e.toString(),
        );
        return;
      }
    }
  }
}
