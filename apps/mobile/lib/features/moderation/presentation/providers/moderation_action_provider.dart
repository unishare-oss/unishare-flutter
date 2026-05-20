import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/moderation/presentation/providers/moderation_repository_provider.dart';

part 'moderation_action_provider.g.dart';

@riverpod
class ModerationAction extends _$ModerationAction {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> approve(String postId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(approvePostUseCaseProvider).call(postId),
    );
  }

  Future<void> reject(String postId, String reason) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(rejectPostUseCaseProvider).call(postId, reason),
    );
  }
}
