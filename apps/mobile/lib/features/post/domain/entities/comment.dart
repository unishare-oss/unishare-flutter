// Pure Dart — zero Flutter or Firebase imports.

class Comment {
  const Comment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String body;
  final DateTime createdAt;
}
