import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/notifications/presentation/providers/notifications_provider.dart';

part 'unread_count_provider.g.dart';

/// Returns the number of unread notifications derived synchronously from
/// [watchNotificationsProvider].
///
/// Returns 0 when the stream is in a loading or error state.
@riverpod
int unreadNotificationCount(Ref ref) {
  final asyncNotifs = ref.watch(watchNotificationsProvider);
  return asyncNotifs.when(
    data: (list) => list.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (e, s) => 0,
  );
}
