import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/requests/domain/entities/suggestion.dart';
import 'package:unishare_mobile/features/requests/domain/usecases/watch_suggestions.dart';

import '../fakes/fake_request_repository.dart';

void main() {
  group('WatchSuggestions', () {
    test('emits suggestions for a given requestId', () async {
      final repo = FakeRequestRepository();
      final useCase = WatchSuggestions(repo);

      final suggestion = fakeSuggestion();
      final emitted = <List<Suggestion>>[];
      final sub = useCase('req-1').listen(emitted.add);

      repo.suggestionsController.add([suggestion]);
      await Future<void>.value();

      expect(emitted, hasLength(1));
      expect(emitted.first.first, same(suggestion));

      await sub.cancel();
      await repo.suggestionsController.close();
    });

    test('streams multiple suggestion events in order', () async {
      final repo = FakeRequestRepository();
      final useCase = WatchSuggestions(repo);

      final s1 = fakeSuggestion(id: 's-1');
      final s2 = fakeSuggestion(id: 's-2');

      final emitted = <List<Suggestion>>[];
      final sub = useCase('req-1').listen(emitted.add);

      repo.suggestionsController.add([s1]);
      await Future<void>.value();
      repo.suggestionsController.add([s1, s2]);
      await Future<void>.value();

      expect(emitted.length, 2);
      expect(emitted[1].length, 2);

      await sub.cancel();
      await repo.suggestionsController.close();
    });
  });
}
