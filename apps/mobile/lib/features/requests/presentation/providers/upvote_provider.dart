import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/requests/presentation/providers/request_repository_provider.dart';

part 'upvote_provider.g.dart';

@riverpod
Stream<bool> hasUpvoted(Ref ref, String requestId) {
  final repo = ref.watch(requestRepositoryProvider);
  return repo.watchHasUpvoted(requestId);
}

@riverpod
class ToggleUpvote extends _$ToggleUpvote {
  @override
  AsyncValue<void> build(String requestId) => const AsyncData(null);

  Future<void> toggle() async {
    state = const AsyncLoading();
    // The stream from hasUpvotedProvider auto-updates when Firestore changes,
    // so no invalidation is needed here.
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(toggleUpvoteRequestUseCaseProvider);
      await useCase(requestId);
    });
  }
}
