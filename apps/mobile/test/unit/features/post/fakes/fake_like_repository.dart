import 'dart:async';

import 'package:unishare_mobile/features/post/domain/repositories/like_repository.dart';

class FakeLikeRepository implements LikeRepository {
  final StreamController<bool> controller = StreamController<bool>.broadcast();

  bool toggleLikeCalled = false;
  String? lastTogglePostId;

  @override
  Stream<bool> watchLikeStatus(String postId) => controller.stream;

  @override
  Future<void> toggleLike(String postId) async {
    toggleLikeCalled = true;
    lastTogglePostId = postId;
  }
}
