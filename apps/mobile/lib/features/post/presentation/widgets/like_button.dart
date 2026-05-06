// TODO(flutter-engineer): implement per SPEC-0006

import 'package:flutter/material.dart';

class LikeButton extends StatelessWidget {
  const LikeButton({
    super.key,
    required this.isLiked,
    required this.count,
    required this.onTap,
    this.enabled = true,
  });

  final bool isLiked;
  final int count;
  final VoidCallback onTap;

  /// False for guest users — disables tap and shows grayed/locked state.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // TODO(flutter-engineer): implement per SPEC-0006
    // - Liked: filled heart icon + count
    // - Unliked: outline heart icon + count
    // - enabled: false → grayed state, no tap response
    throw UnimplementedError('TODO(flutter-engineer): implement per SPEC-0006');
  }
}
