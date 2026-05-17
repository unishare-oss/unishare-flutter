import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:unishare_mobile/features/notifications/domain/entities/notification_item.dart';
import 'package:unishare_mobile/features/notifications/presentation/providers/notification_repository_provider.dart';

part 'notifications_provider.g.dart';

/// Streams the current user's notification list ordered by [createdAt] DESC.
///
/// Emits an empty list immediately when the user is unauthenticated so that
/// downstream consumers never have to handle a null/loading state for auth.
@riverpod
Stream<List<AppNotification>> watchNotifications(Ref ref) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.asData?.value;

  if (user == null) {
    return Stream.value([]);
  }

  return ref.watch(watchNotificationsUseCaseProvider).call(user.id);
}
