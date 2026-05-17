enum NotificationType {
  postCommentAdded,
  postLiked,
  commentReply,
  requestUpvoted,
  suggestionSubmitted,
  suggestionAccepted,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.title,
    required this.body,
    required this.actorId,
    required this.actorName,
    this.actorPhotoUrl,
    required this.targetId,
    required this.targetType,
    required this.targetTitle,
  });

  final String id;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String title;
  final String body;
  final String actorId;
  final String actorName;
  final String? actorPhotoUrl;
  final String targetId;
  final String targetType;
  final String targetTitle;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
    title: title,
    body: body,
    actorId: actorId,
    actorName: actorName,
    actorPhotoUrl: actorPhotoUrl,
    targetId: targetId,
    targetType: targetType,
    targetTitle: targetTitle,
  );
}
