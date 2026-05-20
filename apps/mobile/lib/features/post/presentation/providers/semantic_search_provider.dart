import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/core/logging/app_logger.dart';
import 'package:unishare_mobile/features/post/data/datasources/semantic_search_datasource.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';

part 'semantic_search_provider.g.dart';

/// PROP-0011 Phase 4b — semantic search provider.
///
/// Takes a query string, calls the worker's `/ai/search` for the top
/// matching post IDs, then hydrates them into full Post entities via the
/// post Firestore datasource. Returns the empty list for short queries
/// (< 3 chars) to avoid unnecessary network on every keystroke.
///
/// Debouncing is the caller's responsibility — feed_screen.dart waits
/// ~300ms after the user stops typing before invoking this provider.
/// Failures degrade silently to an empty list so the existing keyword
/// search still works when the worker is down.
@Riverpod(keepAlive: true)
SemanticSearchDatasource semanticSearchDatasource(Ref ref) {
  return SemanticSearchDatasource();
}

@riverpod
Future<List<Post>> semanticSearch(Ref ref, String query) async {
  final trimmed = query.trim();
  if (trimmed.length < 3) return const [];

  final searchDs = ref.watch(semanticSearchDatasourceProvider);
  final postsDs = ref.watch(postFirestoreDatasourceProvider);

  try {
    final hits = await searchDs.search(query: trimmed, limit: 20);
    if (hits.isEmpty) return const [];
    final ids = hits.map((h) => h.postId).toList(growable: false);
    return await postsDs.getPostsByIds(ids);
  } catch (e, st) {
    AppLogger.error('semantic search failed', error: e, stackTrace: st);
    return const [];
  }
}
