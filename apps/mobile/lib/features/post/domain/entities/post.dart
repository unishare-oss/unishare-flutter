// Pure Dart — zero Flutter or Firebase imports.

class Post {
  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.title,
    required this.body,
    required this.mediaUrls,
    required this.tags,
    required this.likesCount,
    required this.createdAt,
    required this.updatedAt,
    this.mediaTypes = const [],
  });

  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String title;
  final String body;
  final List<String> mediaUrls;

  /// Parallel to [mediaUrls]. Values: "image" | "pdf" | "video".
  /// Defaults to empty list for backwards-compat with posts written before SPEC-0006.
  final List<String> mediaTypes;

  final List<String> tags;
  final int likesCount;
  final DateTime createdAt;
  final DateTime updatedAt;
}
