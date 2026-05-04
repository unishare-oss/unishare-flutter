import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/app_user.dart';
import 'auth_repository_provider.dart';

part 'auth_state_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<AppUser?> authState(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
}
