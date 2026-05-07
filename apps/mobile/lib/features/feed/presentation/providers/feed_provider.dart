import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';

part 'feed_provider.g.dart';

@riverpod
Stream<List<Post>> feed(Ref ref) {
  final repository = ref.watch(postRepositoryProvider);
  return repository.watchFeed();
}
