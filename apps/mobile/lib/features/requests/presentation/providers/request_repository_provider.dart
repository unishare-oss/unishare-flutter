import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/requests/data/datasources/request_firestore_datasource.dart';
import 'package:unishare_mobile/features/requests/data/repositories/request_repository_impl.dart';
import 'package:unishare_mobile/features/requests/domain/repositories/request_repository.dart';
import 'package:unishare_mobile/features/requests/domain/usecases/accept_suggestion.dart';
import 'package:unishare_mobile/features/requests/domain/usecases/create_request.dart';
import 'package:unishare_mobile/features/requests/domain/usecases/delete_request.dart';
import 'package:unishare_mobile/features/requests/domain/usecases/remove_suggestion.dart';
import 'package:unishare_mobile/features/requests/domain/usecases/suggest_fulfillment.dart';
import 'package:unishare_mobile/features/requests/domain/usecases/toggle_upvote_request.dart';
import 'package:unishare_mobile/features/requests/domain/usecases/watch_requests.dart';
import 'package:unishare_mobile/features/requests/domain/usecases/watch_suggestions.dart';

part 'request_repository_provider.g.dart';

@Riverpod(keepAlive: true)
RequestFirestoreDatasource requestFirestoreDatasource(Ref ref) {
  return RequestFirestoreDatasource();
}

@Riverpod(keepAlive: true)
RequestRepository requestRepository(Ref ref) {
  return RequestRepositoryImpl(
    datasource: ref.watch(requestFirestoreDatasourceProvider),
  );
}

@Riverpod(keepAlive: true)
WatchRequests watchRequestsUseCase(Ref ref) {
  return WatchRequests(ref.watch(requestRepositoryProvider));
}

@Riverpod(keepAlive: true)
CreateRequest createRequestUseCase(Ref ref) {
  return CreateRequest(ref.watch(requestRepositoryProvider));
}

@Riverpod(keepAlive: true)
WatchSuggestions watchSuggestionsUseCase(Ref ref) {
  return WatchSuggestions(ref.watch(requestRepositoryProvider));
}

@Riverpod(keepAlive: true)
SuggestFulfillment suggestFulfillmentUseCase(Ref ref) {
  return SuggestFulfillment(ref.watch(requestRepositoryProvider));
}

@Riverpod(keepAlive: true)
ToggleUpvoteRequest toggleUpvoteRequestUseCase(Ref ref) {
  return ToggleUpvoteRequest(ref.watch(requestRepositoryProvider));
}

@Riverpod(keepAlive: true)
DeleteRequest deleteRequestUseCase(Ref ref) {
  return DeleteRequest(ref.watch(requestRepositoryProvider));
}

@Riverpod(keepAlive: true)
AcceptSuggestion acceptSuggestionUseCase(Ref ref) {
  return AcceptSuggestion(ref.watch(requestRepositoryProvider));
}

@Riverpod(keepAlive: true)
RemoveSuggestion removeSuggestionUseCase(Ref ref) {
  return RemoveSuggestion(ref.watch(requestRepositoryProvider));
}
