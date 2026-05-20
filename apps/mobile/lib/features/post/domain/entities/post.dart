import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';

enum SummaryStatus {
  pending,
  done,
  flagged,
  unsupportedType,
  error;

  static SummaryStatus? fromFirestore(String? raw) => switch (raw) {
    'pending' => SummaryStatus.pending,
    'done' => SummaryStatus.done,
    'flagged' => SummaryStatus.flagged,
    'unsupported_type' => SummaryStatus.unsupportedType,
    'error' => SummaryStatus.error,
    _ => null,
  };
}

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
    this.viewsCount = 0,
    this.reactionCounts = const {},
    this.departmentId,
    this.externalUrl,
    this.codeSnippetUrl,
    this.summary,
    this.summaryStatus,
    this.summarizedAt,
    this.extractedText,
    this.extractedTextTruncated,
    this.aiTags = const [],
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
  final int viewsCount;
  final Map<String, int> reactionCounts;
  final String? departmentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? externalUrl;
  final String?
  codeSnippetUrl; // Storage download URL for uploaded snippet file

  // SPEC-0009 — AI summary fields
  final String? summary;
  final SummaryStatus? summaryStatus;
  final DateTime? summarizedAt;

  // PROP-0011 — cached source text powering downstream AI features
  // (semantic search, full-RAG chat, practice question generation).
  // For PDF/DOCX this is the extracted body; for images it is the
  // vision model's transcription. Null until a summary completes.
  final String? extractedText;

  /// True when [extractedText] was clipped at the persistence cap.
  /// Surfaces in UI so users can see when the cached text is partial.
  final bool? extractedTextTruncated;

  /// PROP-0011 Phase 2 — AI-derived topic tags (kebab-case). Parallel to the
  /// user-typed [tags] field but rendered distinctly in the UI so authorship
  /// is clear. Empty when the post hasn't been summarized yet or when the
  /// model returned no usable tags.
  final List<String> aiTags;

  // SPEC-0006 alias — PostDetailScreen was authored against this name.
  String get body => description;

  Post copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    PostType? postType,
    int? year,
    String? courseId,
    String? title,
    String? description,
    PostingIdentity? postingIdentity,
    int? semester,
    String? moduleNumber,
    List<String>? mediaUrls,
    List<String>? mediaTypes,
    List<String>? tags,
    int? likesCount,
    int? viewsCount,
    Map<String, int>? reactionCounts,
    String? departmentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? externalUrl,
    String? codeSnippetUrl,
    String? summary,
    SummaryStatus? summaryStatus,
    DateTime? summarizedAt,
    String? extractedText,
    bool? extractedTextTruncated,
    List<String>? aiTags,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      postType: postType ?? this.postType,
      year: year ?? this.year,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      postingIdentity: postingIdentity ?? this.postingIdentity,
      semester: semester ?? this.semester,
      moduleNumber: moduleNumber ?? this.moduleNumber,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaTypes: mediaTypes ?? this.mediaTypes,
      tags: tags ?? this.tags,
      likesCount: likesCount ?? this.likesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      departmentId: departmentId ?? this.departmentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      externalUrl: externalUrl ?? this.externalUrl,
      codeSnippetUrl: codeSnippetUrl ?? this.codeSnippetUrl,
      summary: summary ?? this.summary,
      summaryStatus: summaryStatus ?? this.summaryStatus,
      summarizedAt: summarizedAt ?? this.summarizedAt,
      extractedText: extractedText ?? this.extractedText,
      extractedTextTruncated:
          extractedTextTruncated ?? this.extractedTextTruncated,
      aiTags: aiTags ?? this.aiTags,
    );
  }
}
