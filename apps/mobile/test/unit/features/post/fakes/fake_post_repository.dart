import 'dart:async';
import 'dart:typed_data';

import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';

class FakePostRepository implements PostRepository {
  final StreamController<Post> postController =
      StreamController<Post>.broadcast();

  @override
  Stream<Post> watchPost(String postId) => postController.stream;

  @override
  Stream<List<Post>> watchFeed({int limit = 20}) => throw UnimplementedError();

  @override
  Stream<List<Post>> watchPostsByAuthor(String authorId, {int limit = 50}) =>
      throw UnimplementedError();

  @override
  Future<int> countPostsByAuthor(String authorId) async => 0;

  @override
  Future<void> incrementViewCount(String postId) async {}

  @override
  Future<void> saveDraft(PostDraft draft) => throw UnimplementedError();

  @override
  Future<void> removeDraft(String draftId) => throw UnimplementedError();

  @override
  Future<List<PostDraft>> loadDraftQueue() => throw UnimplementedError();

  @override
  Future<void> publishDraft(
    PostDraft draft, {
    void Function(double progress)? onProgress,
    void Function(int fileIndex, double fileProgress)? onFileProgress,
    void Function(PostDraft)? onDraftUpdated,
    Map<String, Uint8List>? fileDataOverride,
    CancellationToken? cancellationToken,
  }) => throw UnimplementedError();
}
