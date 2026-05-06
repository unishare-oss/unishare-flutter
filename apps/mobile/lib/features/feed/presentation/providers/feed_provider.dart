import 'package:riverpod_annotation/riverpod_annotation.dart';

// TODO: import Post entity and PostRepository provider
// import '../../domain/entities/post.dart';

part 'feed_provider.g.dart';

// Deferred to the data-layer phase. Requires:
//   1. PostRepositoryImpl.watchFeed() wired via postRepositoryProvider
//   2. FilterPreferencesNotifier backed by Firestore + currentUserProvider
//   3. currentUserProvider (not yet implemented)
// The feed screen uses mock data in the meantime and does not read this provider,
// so the UnimplementedError below is not a live crash risk.
@riverpod
class FeedNotifier extends _$FeedNotifier {
  @override
  Future<List<Object>> build() async {
    // final prefsAsync = ref.watch(filterPreferencesNotifierProvider);
    // final tagFilter = prefsAsync.valueOrNull?.selectedTags ?? const [];
    // final repository = ref.read(postRepositoryProvider);
    // return repository.watchFeed(tagFilter: tagFilter).first;
    throw UnimplementedError();
  }

  Future<void> fetchNextPage(Object? cursor) async {
    // TODO: cursor-based pagination
    throw UnimplementedError();
  }
}
