import 'package:unishare_mobile/features/notifications/data/datasources/notification_firestore_datasource.dart';
import 'package:unishare_mobile/features/notifications/domain/entities/notification_item.dart';
import 'package:unishare_mobile/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl({required this.datasource});

  final NotificationFirestoreDatasource datasource;

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) =>
      datasource.watchNotifications(userId);

  @override
  Future<void> markAsRead(String userId, String notificationId) =>
      datasource.markAsRead(userId, notificationId);

  @override
  Future<void> markAllAsRead(String userId) => datasource.markAllAsRead(userId);

  @override
  Future<void> registerFcmToken(String userId, String token, String platform) =>
      datasource.registerFcmToken(userId, token, platform);

  @override
  Future<void> removeFcmToken(String userId, String token) =>
      datasource.removeFcmToken(userId, token);
}
