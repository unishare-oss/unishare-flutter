// Pure Dart — zero Flutter or Firebase imports.

enum RequestStatus { open, fulfilled }

class ContentRequest {
  const ContentRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.requesterAvatar,
    required this.departmentId,
    required this.departmentName,
    required this.year,
    required this.courseId,
    required this.courseName,
    required this.title,
    this.description,
    required this.status,
    this.fulfilledByPostId,
    this.fulfilledByPostTitle,
    required this.upvoteCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String requesterId;
  final String requesterName;
  final String? requesterAvatar;
  final String departmentId;
  final String departmentName;
  final String year;
  final String courseId;
  final String courseName;
  final String title;
  final String? description;
  final RequestStatus status;
  final String? fulfilledByPostId;
  final String? fulfilledByPostTitle;
  final int upvoteCount;
  final DateTime createdAt;
  final DateTime updatedAt;
}
