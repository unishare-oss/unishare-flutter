import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/notifications/data/datasources/notification_firestore_datasource.dart';
import 'package:unishare_mobile/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:unishare_mobile/features/notifications/domain/repositories/notification_repository.dart';
import 'package:unishare_mobile/features/notifications/domain/usecases/mark_all_notifications_read.dart';
import 'package:unishare_mobile/features/notifications/domain/usecases/mark_notification_read.dart';
import 'package:unishare_mobile/features/notifications/domain/usecases/watch_notifications.dart';

part 'notification_repository_provider.g.dart';

@Riverpod(keepAlive: true)
NotificationFirestoreDatasource notificationFirestoreDatasource(Ref ref) {
  return NotificationFirestoreDatasource();
}

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) {
  return NotificationRepositoryImpl(
    datasource: ref.watch(notificationFirestoreDatasourceProvider),
  );
}

@Riverpod(keepAlive: true)
WatchNotifications watchNotificationsUseCase(Ref ref) {
  return WatchNotifications(ref.watch(notificationRepositoryProvider));
}

@Riverpod(keepAlive: true)
MarkNotificationRead markNotificationReadUseCase(Ref ref) {
  return MarkNotificationRead(ref.watch(notificationRepositoryProvider));
}

@Riverpod(keepAlive: true)
MarkAllNotificationsRead markAllNotificationsReadUseCase(Ref ref) {
  return MarkAllNotificationsRead(ref.watch(notificationRepositoryProvider));
}
