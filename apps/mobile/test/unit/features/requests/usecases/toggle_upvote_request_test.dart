import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/requests/domain/usecases/toggle_upvote_request.dart';

import '../fakes/fake_request_repository.dart';

void main() {
  group('ToggleUpvoteRequest', () {
    test('calls repository toggleUpvote', () async {
      final repo = FakeRequestRepository();
      final useCase = ToggleUpvoteRequest(repo);

      await useCase('req-1');

      expect(repo.toggleUpvoteCalled, isTrue);
    });

    test('passes requestId to repository', () async {
      final repo = FakeRequestRepository();
      final useCase = ToggleUpvoteRequest(repo);

      await useCase('req-special');

      expect(repo.lastToggleUpvoteRequestId, 'req-special');
    });

    test('hasUpvoted returns false when not upvoted', () async {
      final repo = FakeRequestRepository()..hasUpvotedResult = false;

      final result = await repo.hasUpvoted('req-1');

      expect(result, isFalse);
    });

    test('hasUpvoted returns true when upvoted', () async {
      final repo = FakeRequestRepository()..hasUpvotedResult = true;

      final result = await repo.hasUpvoted('req-1');

      expect(result, isTrue);
    });

    test('toggle add — hasUpvoted transitions from false to true', () async {
      // Simulate add: before toggle the user has NOT upvoted;
      // after toggle the repository reports upvoted.
      final repo = FakeRequestRepository()..hasUpvotedResult = false;
      final useCase = ToggleUpvoteRequest(repo);

      final beforeToggle = await repo.hasUpvoted('req-1');
      expect(beforeToggle, isFalse);

      // Calling toggle should invoke the repository.
      await useCase('req-1');
      expect(repo.toggleUpvoteCalled, isTrue);

      // Simulate the repository state flip (as if it toggled from false → true).
      repo.hasUpvotedResult = true;
      final afterToggle = await repo.hasUpvoted('req-1');
      expect(afterToggle, isTrue);
    });

    test('toggle remove — hasUpvoted transitions from true to false', () async {
      // Simulate remove: before toggle the user HAS upvoted;
      // after toggle the repository reports not upvoted.
      final repo = FakeRequestRepository()..hasUpvotedResult = true;
      final useCase = ToggleUpvoteRequest(repo);

      final beforeToggle = await repo.hasUpvoted('req-1');
      expect(beforeToggle, isTrue);

      await useCase('req-1');
      expect(repo.toggleUpvoteCalled, isTrue);

      // Simulate the repository state flip (as if it toggled from true → false).
      repo.hasUpvotedResult = false;
      final afterToggle = await repo.hasUpvoted('req-1');
      expect(afterToggle, isFalse);
    });
  });
}
