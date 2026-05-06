import 'dart:async';

import 'package:unishare_mobile/features/post/domain/entities/comment.dart';
import 'package:unishare_mobile/features/post/domain/repositories/comment_repository.dart';

class FakeCommentRepository implements CommentRepository {
  final StreamController<List<Comment>> controller =
      StreamController<List<Comment>>.broadcast();

  String? lastAddedPostId;
  String? lastAddedBody;

  @override
  Stream<List<Comment>> watchComments(String postId) => controller.stream;

  @override
  Future<void> addComment(String postId, String body) async {
    lastAddedPostId = postId;
    lastAddedBody = body;
  }
}
