import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/saved/domain/entities/saved_post.dart';
import 'package:unishare_mobile/features/saved/domain/usecases/get_saved_posts.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/saved_post_repository_provider.dart';

part 'saved_posts_provider.g.dart';

@riverpod
Stream<List<SavedPost>> savedPosts(Ref ref) {
  final repository = ref.watch(savedPostRepositoryProvider);
  return GetSavedPosts(repository).call();
}
