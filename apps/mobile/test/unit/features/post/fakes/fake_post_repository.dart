import 'dart:async';

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
  Future<void> saveDraft(PostDraft draft) => throw UnimplementedError();

  @override
  Future<void> removeDraft(String draftId) => throw UnimplementedError();

  @override
  Future<List<PostDraft>> loadDraftQueue() => throw UnimplementedError();

  @override
  Future<void> publishDraft(
    PostDraft draft, {
    void Function(double progress)? onProgress,
  }) => throw UnimplementedError();
}
