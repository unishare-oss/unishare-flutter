import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/requests/domain/entities/suggestion.dart';
import 'package:unishare_mobile/features/requests/presentation/providers/request_repository_provider.dart';

part 'suggestions_provider.g.dart';

@riverpod
Stream<List<Suggestion>> suggestions(Ref ref, String requestId) {
  final useCase = ref.watch(watchSuggestionsUseCaseProvider);
  return useCase(requestId);
}
