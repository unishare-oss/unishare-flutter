import 'package:unishare_mobile/features/post/domain/entities/code_snippet.dart';

enum DraftStatus { idle, uploading, publishing, published, queued, error }

enum PostType {
  lectureNote,
  exercise;

  /// Human-facing label shown in type badges across the app (feed, post detail,
  /// saved, moderation). Single source of truth — keep call sites using this
  /// instead of inlining `'NOTE'`/`'EXERCISE'` literals.
  String get displayLabel => switch (this) {
    PostType.lectureNote => 'NOTE',
    PostType.exercise => 'EXERCISE',
  };

  /// Parses a stored enum name (e.g. `"lectureNote"`) case-insensitively.
  /// Unknown values fall back to [PostType.exercise].
  static PostType fromName(String name) {
    final lower = name.toLowerCase();
    return PostType.values.firstWhere(
      (t) => t.name.toLowerCase() == lower,
      orElse: () => PostType.exercise,
    );
  }
}

enum PostingIdentity { named, anonymous }

class PostDraft {
  const PostDraft({
    required this.id,
    required this.postType,
    required this.year,
    required this.courseId,
    required this.departmentId,
    required this.title,
    required this.description,
    required this.postingIdentity,
    required this.semester,
    required this.moduleNumber,
    required this.localMediaPaths,
    required this.uploadedUrls,
    required this.createdAt,
    this.externalUrl,
    this.tags = const [],
    this.codeSnippet,
    this.status = DraftStatus.idle,
    this.errorMessage,
  });

  final String id;
  final PostType postType;

  // Step 2
  final int year; // e.g. 2
  final String courseId; // Firestore reference data ID
  final String departmentId;

  // Step 3
  final String title;
  final String description;
  final PostingIdentity postingIdentity;
  final int semester; // 1 or 2
  final String moduleNumber;
  final String? externalUrl;
  final List<String> tags; // max 5

  // Step 4
  final List<String> localMediaPaths;
  final Map<String, String> uploadedUrls; // localPath → Storage download URL
  final CodeSnippet? codeSnippet;

  final DateTime createdAt;
  final DraftStatus status;
  final String? errorMessage;

  PostDraft copyWith({
    PostType? postType,
    int? year,
    String? courseId,
    String? departmentId,
    String? title,
    String? description,
    PostingIdentity? postingIdentity,
    int? semester,
    String? moduleNumber,
    String? externalUrl,
    List<String>? tags,
    List<String>? localMediaPaths,
    Map<String, String>? uploadedUrls,
    CodeSnippet? codeSnippet,
    DraftStatus? status,
    String? errorMessage,
    bool clearExternalUrl = false,
    bool clearCodeSnippet = false,
    bool clearErrorMessage = false,
  }) {
    return PostDraft(
      id: id,
      postType: postType ?? this.postType,
      year: year ?? this.year,
      courseId: courseId ?? this.courseId,
      departmentId: departmentId ?? this.departmentId,
      title: title ?? this.title,
      description: description ?? this.description,
      postingIdentity: postingIdentity ?? this.postingIdentity,
      semester: semester ?? this.semester,
      moduleNumber: moduleNumber ?? this.moduleNumber,
      externalUrl: clearExternalUrl ? null : (externalUrl ?? this.externalUrl),
      tags: tags ?? this.tags,
      localMediaPaths: localMediaPaths ?? this.localMediaPaths,
      uploadedUrls: uploadedUrls ?? this.uploadedUrls,
      codeSnippet: clearCodeSnippet ? null : (codeSnippet ?? this.codeSnippet),
      createdAt: createdAt,
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}
