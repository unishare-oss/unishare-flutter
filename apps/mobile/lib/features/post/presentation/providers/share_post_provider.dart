import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';

part 'share_post_provider.g.dart';

@riverpod
class SharePost extends _$SharePost {
  @override
  FutureOr<void> build() {}

  Future<void> share(Post post) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(sharePostUseCaseProvider).call(post),
    );
  }
}
