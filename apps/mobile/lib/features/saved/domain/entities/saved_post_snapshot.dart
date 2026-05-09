// Pure Dart — zero Flutter or Firebase imports.

class SavedPostSnapshot {
  const SavedPostSnapshot({
    required this.title,
    required this.authorName,
    required this.authorAvatar,
    required this.courseId,
    required this.postType,
    required this.tags,
    required this.commentsCount,
  });

  final String title;
  final String authorName; // empty string when anonymous
  final String authorAvatar; // empty string when anonymous
  final String courseId;
  final String postType; // PostType.name — e.g. "note", "assignment"
  final List<String> tags;
  final int commentsCount; // captured at save time; may be stale
}
