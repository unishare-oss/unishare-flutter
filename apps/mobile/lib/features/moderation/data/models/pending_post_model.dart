import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unishare_mobile/features/moderation/data/models/moderation_verdict_model.dart';
import 'package:unishare_mobile/features/moderation/domain/entities/pending_post.dart';

class PendingPostModel {
  const PendingPostModel({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.tags,
    required this.postType,
    required this.createdAt,
    this.aiVerdictModel,
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
  final ModerationVerdictModel? aiVerdictModel;
  final String? moderatedBy;
  final DateTime? moderatedAt;

  factory PendingPostModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    final createdAtTs = data['createdAt'];
    final createdAt = createdAtTs is Timestamp
        ? createdAtTs.toDate()
        : DateTime.fromMillisecondsSinceEpoch((createdAtTs as int? ?? 0));

    final moderatedAtTs = data['moderatedAt'];
    final moderatedAt = moderatedAtTs is Timestamp
        ? moderatedAtTs.toDate()
        : null;

    final verdictMap = data['aiVerdict'];
    final aiVerdictModel = verdictMap is Map<String, dynamic>
        ? ModerationVerdictModel.fromMap(verdictMap)
        : null;

    final rawTags = data['tags'];
    final tags = rawTags is List
        ? rawTags.map((t) => t.toString()).toList()
        : <String>[];

    return PendingPostModel(
      id: doc.id,
      title: (data['title'] as String? ?? ''),
      description: (data['description'] as String? ?? ''),
      authorId: (data['authorId'] as String? ?? ''),
      authorName: (data['authorName'] as String? ?? ''),
      tags: tags,
      postType: (data['postType'] as String? ?? ''),
      createdAt: createdAt,
      aiVerdictModel: aiVerdictModel,
      moderatedBy: data['moderatedBy'] as String?,
      moderatedAt: moderatedAt,
    );
  }

  PendingPost toEntity() => PendingPost(
    id: id,
    title: title,
    description: description,
    authorId: authorId,
    authorName: authorName,
    tags: tags,
    postType: postType,
    createdAt: createdAt,
    aiVerdict: aiVerdictModel?.toEntity(),
    moderatedBy: moderatedBy,
    moderatedAt: moderatedAt,
  );
}
