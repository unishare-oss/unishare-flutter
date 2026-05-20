import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/moderation/domain/entities/pending_post.dart';
import 'package:unishare_mobile/features/moderation/presentation/providers/moderation_repository_provider.dart';

part 'moderation_queue_provider.g.dart';

@riverpod
Stream<List<PendingPost>> moderationQueue(Ref ref) {
  return ref.watch(getPendingPostsUseCaseProvider).call();
}
