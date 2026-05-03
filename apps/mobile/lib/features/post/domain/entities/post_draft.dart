enum DraftStatus { idle, uploading, publishing, published, queued, error }

class PostDraft {
  const PostDraft({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.localMediaPaths,
    required this.uploadedUrls,
    required this.createdAt,
    this.status = DraftStatus.idle,
    this.errorMessage,
  });

  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final List<String> localMediaPaths;
  final Map<String, String> uploadedUrls;
  final DateTime createdAt;
  final DraftStatus status;
  final String? errorMessage;

  PostDraft copyWith({
    String? title,
    String? body,
    List<String>? tags,
    List<String>? localMediaPaths,
    Map<String, String>? uploadedUrls,
    DraftStatus? status,
    String? errorMessage,
  }) {
    return PostDraft(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      tags: tags ?? this.tags,
      localMediaPaths: localMediaPaths ?? this.localMediaPaths,
      uploadedUrls: uploadedUrls ?? this.uploadedUrls,
      createdAt: createdAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
