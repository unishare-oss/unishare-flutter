// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/moderation/domain/entities/moderation_verdict.dart';

class PendingPost {
  const PendingPost({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.tags,
    required this.postType,
    required this.createdAt,
    this.mediaUrls = const [],
    this.mediaTypes = const [],
    this.aiVerdict,
    this.moderatedBy,
    this.moderatedAt,
    this.rejectionReason,
  });

  final String id;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final List<String> tags;
  final String postType;
  final DateTime createdAt;

  /// Attachment URLs, parallel to [mediaTypes]. Lets moderators preview the
  /// actual file before approving/rejecting. Empty when the post has no media.
  final List<String> mediaUrls;

  /// Parallel to [mediaUrls]. Values: "image" | "pdf" | "video".
  final List<String> mediaTypes;

  /// null while the Cloud Function is still processing
  final ModerationVerdict? aiVerdict;

  final String? moderatedBy;
  final DateTime? moderatedAt;

  /// Moderator-supplied reason; set when the post was rejected. Shown in the
  /// Rejected tab of the moderation screen.
  final String? rejectionReason;
}
