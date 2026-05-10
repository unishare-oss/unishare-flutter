import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';

part 'my_posts_provider.g.dart';

@riverpod
Stream<List<Post>> myPosts(Ref ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    return const Stream.empty();
  }
  return ref.watch(watchMyPostsUseCaseProvider).call(uid);
}
