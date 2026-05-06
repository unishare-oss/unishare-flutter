import 'post_draft.dart';

class Post {
  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.postType,
    required this.year,
    required this.courseId,
    required this.title,
    required this.description,
    required this.postingIdentity,
    required this.semester,
    required this.moduleNumber,
    required this.mediaUrls,
    required this.tags,
    required this.likesCount,
    required this.createdAt,
    required this.updatedAt,
    this.externalUrl,
    this.codeSnippetUrl,
  });

  final String id;
  final String authorId;
  final String authorName; // empty string when anonymous
  final String authorAvatar; // empty string when anonymous
  final PostType postType;
  final int year;
  final String courseId;
  final String title;
  final String description;
  final PostingIdentity postingIdentity;
  final int semester;
  final String moduleNumber;
  final List<String> mediaUrls;
  final List<String> tags;
  final int likesCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? externalUrl;
  final String?
  codeSnippetUrl; // Storage download URL for uploaded snippet file
}
