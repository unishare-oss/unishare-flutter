import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/saved/domain/usecases/is_post_saved.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/saved_post_repository_provider.dart';

part 'is_post_saved_provider.g.dart';

@riverpod
Stream<bool> isPostSaved(Ref ref, String postId) {
  final repository = ref.watch(savedPostRepositoryProvider);
  return IsPostSaved(repository).call(postId);
}
