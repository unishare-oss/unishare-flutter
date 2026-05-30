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
    this.aiVerdict,
    this.moderatedBy,
    this.moderatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final List<String> tags;
  final String postType;
  final DateTime createdAt;

  /// null while the Cloud Function is still processing
  final ModerationVerdict? aiVerdict;

  final String? moderatedBy;
  final DateTime? moderatedAt;
}
