import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/requests/domain/usecases/create_request.dart';

import '../fakes/fake_request_repository.dart';

void main() {
  group('CreateRequest', () {
    late FakeRequestRepository repo;
    late CreateRequest useCase;

    setUp(() {
      repo = FakeRequestRepository();
      useCase = CreateRequest(repo);
    });

    test('calls repository with correct params', () async {
      await useCase(
        departmentId: 'dept-1',
        departmentName: 'CS',
        year: '2',
        courseId: 'CSC234',
        courseName: 'CSC234',
        title: 'Notes needed',
      );

      expect(repo.createRequestCalled, isTrue);
      expect(repo.lastCreateRequestTitle, 'Notes needed');
    });

    test('throws when title is empty', () async {
      expect(
        () => useCase(
          departmentId: 'dept-1',
          departmentName: 'CS',
          year: '2',
          courseId: 'CSC234',
          courseName: 'CSC234',
          title: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(repo.createRequestCalled, isFalse);
    });

    test('throws when title exceeds 120 characters', () async {
      final longTitle = 'A' * 121;
      expect(
        () => useCase(
          departmentId: 'dept-1',
          departmentName: 'CS',
          year: '2',
          courseId: 'CSC234',
          courseName: 'CSC234',
          title: longTitle,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when description exceeds 500 characters', () async {
      final longDesc = 'B' * 501;
      expect(
        () => useCase(
          departmentId: 'dept-1',
          departmentName: 'CS',
          year: '2',
          courseId: 'CSC234',
          courseName: 'CSC234',
          title: 'Valid title',
          description: longDesc,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('trims whitespace from title before calling repository', () async {
      await useCase(
        departmentId: 'dept-1',
        departmentName: 'CS',
        year: '2',
        courseId: 'CSC234',
        courseName: 'CSC234',
        title: '  Trimmed title  ',
      );

      expect(repo.lastCreateRequestTitle, 'Trimmed title');
    });
  });
}
