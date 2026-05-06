// TODO(flutter-engineer): implement per SPEC-0006

import 'package:flutter/material.dart';

import '../../domain/entities/post.dart';

class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({
    super.key,
    required this.postId,
    this.seed,
  });

  final String postId;

  /// Optional warm-start seed from GoRouter extra.
  /// Null on cold-start (deep link / push notification).
  final Post? seed;

  @override
  Widget build(BuildContext context) {
    // TODO(flutter-engineer): implement per SPEC-0006
    // - Watch postDetailProvider(postId, seed: seed)
    // - Watch commentsProvider(postId)
    // - Watch userLikeStatusProvider(postId)
    // - Show skeleton on AsyncLoading
    // - Guest-mode: disable LikeButton + hide comment input
    // - Navbar must be absent (route is outside StatefulShellRoute)
    throw UnimplementedError('TODO(flutter-engineer): implement per SPEC-0006');
  }
}
