import 'package:unishare_mobile/features/notifications/domain/entities/notification_item.dart';
import 'package:unishare_mobile/features/notifications/domain/repositories/notification_repository.dart';

class WatchNotifications {
  const WatchNotifications(this._repository);
  final NotificationRepository _repository;

  Stream<List<AppNotification>> call(String userId) =>
      _repository.watchNotifications(userId);
}
