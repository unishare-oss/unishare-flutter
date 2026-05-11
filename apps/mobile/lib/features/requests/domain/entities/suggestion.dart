// Pure Dart — zero Flutter or Firebase imports.

class Suggestion {
  const Suggestion({
    required this.id,
    required this.postId,
    required this.postTitle,
    required this.postType,
    required this.suggestedByUserId,
    required this.suggestedByName,
    this.suggestedByAvatar,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String postTitle;
  final String postType;
  final String suggestedByUserId;
  final String suggestedByName;
  final String? suggestedByAvatar;
  final DateTime createdAt;
}
