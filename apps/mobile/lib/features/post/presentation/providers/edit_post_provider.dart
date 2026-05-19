import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';

part 'edit_post_provider.g.dart';

@riverpod
class EditPostNotifier extends _$EditPostNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> save({
    required String postId,
    required String title,
    required String description,
    required List<String> tags,
    String? externalUrl,
    required String moduleNumber,
    required bool descriptionChanged,
    required SummaryStatus? currentSummaryStatus,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(updatePostUseCaseProvider).call(
            postId: postId,
            title: title,
            description: description,
            tags: tags,
            externalUrl: externalUrl,
            moduleNumber: moduleNumber,
            descriptionChanged: descriptionChanged,
            currentSummaryStatus: currentSummaryStatus,
          ),
    );
  }
}
