import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/app_user.dart';
import 'auth_repository_provider.dart';

part 'current_user_provider.g.dart';

@riverpod
Future<AppUser?> currentUser(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getCurrentUser();
}
