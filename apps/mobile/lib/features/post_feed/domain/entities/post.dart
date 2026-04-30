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
    required this.isLikedByCurrentUser,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String title;
  final String body;
  final List<String> mediaUrls;
  final List<String> tags;
  final int likesCount;
  final bool isLikedByCurrentUser;
  final DateTime createdAt;
  final DateTime updatedAt;

  Post copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? title,
    String? body,
    List<String>? mediaUrls,
    List<String>? tags,
    int? likesCount,
    bool? isLikedByCurrentUser,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      title: title ?? this.title,
      body: body ?? this.body,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      tags: tags ?? this.tags,
      likesCount: likesCount ?? this.likesCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
