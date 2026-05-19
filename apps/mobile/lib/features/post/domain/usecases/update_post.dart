// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';

class UpdatePost {
  const UpdatePost(this._repository);
  final PostRepository _repository;

  Future<void> call({
    required String postId,
    required String title,
    required String description,
    required List<String> tags,
    String? externalUrl,
    required String moduleNumber,
    required bool descriptionChanged,
    required SummaryStatus? currentSummaryStatus,
  }) {
    if (title.trim().isEmpty) throw ArgumentError('title_required');
    if (description.trim().isEmpty) throw ArgumentError('description_required');
    return _repository.updatePost(
      postId: postId,
      title: title.trim(),
      description: description.trim(),
      tags: tags,
      externalUrl: externalUrl,
      moduleNumber: moduleNumber,
      descriptionChanged: descriptionChanged,
      currentSummaryStatus: currentSummaryStatus,
    );
  }
}
