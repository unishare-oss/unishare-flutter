import 'package:unishare_mobile/features/notifications/domain/repositories/notification_repository.dart';

class MarkNotificationRead {
  const MarkNotificationRead(this._repository);
  final NotificationRepository _repository;

  Future<void> call(String userId, String notificationId) =>
      _repository.markAsRead(userId, notificationId);
}
