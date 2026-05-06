import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';

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
    this.mediaTypes = const [],
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

  /// Parallel to [mediaUrls]. Values: "image" | "pdf" | "video".
  /// Defaults to empty list for backwards-compat with posts written before SPEC-0006.
  final List<String> mediaTypes;

  final List<String> tags;
  final int likesCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? externalUrl;
  final String?
  codeSnippetUrl; // Storage download URL for uploaded snippet file

  // SPEC-0006 alias — PostDetailScreen was authored against this name.
  String get body => description;
}
