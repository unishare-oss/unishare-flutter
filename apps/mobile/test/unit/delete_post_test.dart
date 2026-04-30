import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unishare_mobile/features/post_feed/domain/repositories/post_repository.dart';
import 'package:unishare_mobile/features/post_feed/domain/usecases/delete_post.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late MockPostRepository repo;
  late DeletePost useCase;

  setUp(() {
    repo = MockPostRepository();
    useCase = DeletePost(repo);
  });

  test('delegates to repository', () async {
    when(() => repo.deletePost('p1')).thenAnswer((_) async {});

    await useCase('p1');

    verify(() => repo.deletePost('p1')).called(1);
  });

  test('propagates repository errors', () {
    when(() => repo.deletePost('p1')).thenThrow(Exception('Network error'));

    expect(() => useCase('p1'), throwsException);
  });
}
