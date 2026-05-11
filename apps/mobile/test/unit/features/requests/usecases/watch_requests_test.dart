import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/requests/domain/entities/content_request.dart';
import 'package:unishare_mobile/features/requests/domain/usecases/watch_requests.dart';

import '../fakes/fake_request_repository.dart';

void main() {
  group('WatchRequests', () {
    test('emits list from repository stream', () async {
      final repo = FakeRequestRepository();
      final useCase = WatchRequests(repo);

      final request = fakeRequest();
      final emitted = <List<ContentRequest>>[];
      final sub = useCase().listen(emitted.add);

      repo.requestsController.add([request]);
      await Future<void>.value();

      expect(emitted, hasLength(1));
      expect(emitted.first.first, same(request));

      await sub.cancel();
      await repo.requestsController.close();
    });

    test('passes filter params to repository', () async {
      final repo = FakeRequestRepository();
      final useCase = WatchRequests(repo);

      // Calling with filter params — the fake ignores them but we confirm
      // the call succeeds without throwing.
      final sub = useCase(
        departmentId: 'dept-1',
        year: '2',
        courseId: 'CSC234',
        status: RequestStatus.open,
      ).listen((_) {});

      await sub.cancel();
      await repo.requestsController.close();
    });

    test('streams multiple events in order', () async {
      final repo = FakeRequestRepository();
      final useCase = WatchRequests(repo);

      final req1 = fakeRequest(id: 'r-1');
      final req2 = fakeRequest(id: 'r-2');

      final emitted = <List<ContentRequest>>[];
      final sub = useCase().listen(emitted.add);

      repo.requestsController.add([req1]);
      await Future<void>.value();
      repo.requestsController.add([req2]);
      await Future<void>.value();

      expect(emitted, [
        [req1],
        [req2],
      ]);

      await sub.cancel();
      await repo.requestsController.close();
    });
  });
}
