// TODO(flutter-engineer): implement per SPEC-0004 API contracts
// Check for a pre-existing file from PROP-0003 before finalising — do not break watchFeed.

import 'dart:typed_data';

import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';

abstract interface class PostRepository {
  Stream<List<Post>> watchFeed({int limit = 20});

  Future<void> saveDraft(PostDraft draft);
  Future<void> removeDraft(String draftId);
  Future<List<PostDraft>> loadDraftQueue();
  Future<void> publishDraft(
    PostDraft draft, {
    void Function(double progress)? onProgress,
    // Web uploads: maps localMediaPaths key → file bytes (path is null on web)
    Map<String, Uint8List>? fileDataOverride,
  });
}
