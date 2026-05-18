import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/auth_state_provider.dart';

part 'guest_mode_provider.g.dart';

@Riverpod(keepAlive: true)
bool guestMode(Ref ref) {
  final authAsync = ref.watch(authStateProvider);
  return authAsync.asData?.value?.isAnonymous ?? false;
}
