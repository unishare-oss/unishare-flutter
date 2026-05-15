import 'package:unishare_mobile/features/notifications/domain/entities/notification_item.dart';

abstract interface class NotificationRepository {
  Stream<List<AppNotification>> watchNotifications(String userId);
  Future<void> markAsRead(String userId, String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> registerFcmToken(String userId, String token, String platform);
  Future<void> removeFcmToken(String userId, String token);
}
