import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/requests/presentation/providers/request_repository_provider.dart';

part 'upvote_provider.g.dart';

@riverpod
Future<bool> hasUpvoted(Ref ref, String requestId) {
  final repo = ref.watch(requestRepositoryProvider);
  return repo.hasUpvoted(requestId);
}

@riverpod
class ToggleUpvote extends _$ToggleUpvote {
  @override
  AsyncValue<void> build(String requestId) => const AsyncData(null);

  Future<void> toggle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(toggleUpvoteRequestUseCaseProvider);
      await useCase(requestId);
      ref.invalidate(hasUpvotedProvider(requestId));
    });
  }
}
