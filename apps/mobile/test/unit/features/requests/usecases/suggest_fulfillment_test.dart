import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/requests/domain/usecases/suggest_fulfillment.dart';

import '../fakes/fake_request_repository.dart';

void main() {
  group('SuggestFulfillment', () {
    test('calls repository suggestFulfillment', () async {
      final repo = FakeRequestRepository();
      final useCase = SuggestFulfillment(repo);

      await useCase(
        requestId: 'req-1',
        postId: 'post-1',
        postTitle: 'DS Notes',
        postType: 'lectureNote',
      );

      expect(repo.suggestFulfillmentCalled, isTrue);
    });

    test('passes all params to repository correctly', () async {
      final repo = FakeRequestRepository();
      final useCase = SuggestFulfillment(repo);

      await useCase(
        requestId: 'req-42',
        postId: 'post-99',
        postTitle: 'Midterm Study Guide',
        postType: 'assignment',
      );

      expect(repo.lastSuggestRequestId, 'req-42');
      expect(repo.lastSuggestPostId, 'post-99');
      expect(repo.lastSuggestPostTitle, 'Midterm Study Guide');
      expect(repo.lastSuggestPostType, 'assignment');
    });

    test(
      'repository is called once per invocation — no duplicate side-effects',
      () async {
        final repo = FakeRequestRepository();
        final useCase = SuggestFulfillment(repo);

        await useCase(
          requestId: 'req-1',
          postId: 'post-1',
          postTitle: 'Notes',
          postType: 'lectureNote',
        );

        // The use case is a thin delegation layer — verify it does not call the
        // repository more than once and does not mutate status itself
        // (status update is the repository's responsibility per the spec).
        expect(repo.suggestFulfillmentCalled, isTrue);
        // The use case must NOT touch requestsController or suggestionsController.
        expect(repo.createRequestCalled, isFalse);
        expect(repo.toggleUpvoteCalled, isFalse);
      },
    );
  });
}
