import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';

part 'my_posts_provider.g.dart';

@riverpod
Stream<List<Post>> myPosts(Ref ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.id;
  if (uid == null) {
    return Stream.value(const []);
  }
  return ref.watch(watchMyPostsUseCaseProvider).call(uid);
}
