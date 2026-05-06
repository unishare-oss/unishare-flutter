import 'package:riverpod_annotation/riverpod_annotation.dart';

// TODO: import Post entity and PostRepository provider
// import '../../domain/entities/post.dart';

part 'feed_provider.g.dart';

// TODO: wire postRepositoryProvider and filterPreferencesNotifierProvider
@riverpod
class FeedNotifier extends _$FeedNotifier {
  @override
  Future<List<Object>> build() async {
    // TODO: read active filter from filterPreferencesNotifierProvider
    // final prefsAsync = ref.watch(filterPreferencesNotifierProvider);
    // final tagFilter = prefsAsync.valueOrNull?.selectedTags ?? const [];
    // final repository = ref.read(postRepositoryProvider);
    // return repository.getPostFeed(tagFilter: tagFilter);
    throw UnimplementedError();
  }

  Future<void> fetchNextPage(Object? cursor) async {
    // TODO: implement cursor-based next page fetch
    throw UnimplementedError();
  }
}
