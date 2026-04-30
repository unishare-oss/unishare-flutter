import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unishare_mobile/features/post_feed/domain/repositories/post_repository.dart';
import 'package:unishare_mobile/features/post_feed/domain/usecases/toggle_like.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late MockPostRepository repo;
  late ToggleLike useCase;

  setUp(() {
    repo = MockPostRepository();
    useCase = ToggleLike(repo);
  });

  test('delegates like=true to repository', () async {
    when(() => repo.toggleLike('p1', liked: true)).thenAnswer((_) async {});

    await useCase('p1', liked: true);

    verify(() => repo.toggleLike('p1', liked: true)).called(1);
  });

  test('delegates like=false to repository', () async {
    when(() => repo.toggleLike('p1', liked: false)).thenAnswer((_) async {});

    await useCase('p1', liked: false);

    verify(() => repo.toggleLike('p1', liked: false)).called(1);
  });
}
