import 'package:unishare_mobile/features/notifications/domain/repositories/notification_repository.dart';

class MarkAllNotificationsRead {
  const MarkAllNotificationsRead(this._repository);
  final NotificationRepository _repository;

  Future<void> call(String userId) => _repository.markAllAsRead(userId);
}
