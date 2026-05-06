// TODO(flutter-engineer): implement per SPEC-0006

import 'package:flutter/material.dart';

class AttachmentCarousel extends StatelessWidget {
  const AttachmentCarousel({
    super.key,
    required this.mediaUrls,
    required this.mediaTypes,
  });

  /// Download URLs for all attachments.
  final List<String> mediaUrls;

  /// Parallel to mediaUrls. Values: "image" | "pdf" | "video".
  /// Falls back to "image" if shorter than mediaUrls or on unknown value.
  final List<String> mediaTypes;

  @override
  Widget build(BuildContext context) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();
    // TODO(flutter-engineer): implement per SPEC-0006
    // - Use ListView.builder (never ListView) for horizontal scroll
    // - "image" → CachedNetworkImage
    // - "pdf"   → PDF thumbnail + full-screen viewer on tap (approved package TBD)
    // - "video" → Video thumbnail + play overlay + full-screen player on tap
    // - Mismatched array lengths fall back to "image"
    throw UnimplementedError('TODO(flutter-engineer): implement per SPEC-0006');
  }
}
