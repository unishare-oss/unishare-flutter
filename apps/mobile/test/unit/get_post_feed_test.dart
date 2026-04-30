import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unishare_mobile/features/post_feed/domain/entities/post_feed_page.dart';
import 'package:unishare_mobile/features/post_feed/domain/repositories/post_repository.dart';
import 'package:unishare_mobile/features/post_feed/domain/usecases/get_post_feed.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late MockPostRepository repo;
  late GetPostFeed useCase;

  setUp(() {
    repo = MockPostRepository();
    useCase = GetPostFeed(repo);
  });

  test('delegates to repository with default page and pageSize', () async {
    when(() => repo.getPostFeed(page: 0, pageSize: 20))
        .thenAnswer((_) async => const PostFeedPage(posts: [], page: 0, hasMore: false));

    await useCase();

    verify(() => repo.getPostFeed(page: 0, pageSize: 20)).called(1);
  });

  test('passes custom page and pageSize to repository', () async {
    when(() => repo.getPostFeed(page: 2, pageSize: 10))
        .thenAnswer((_) async => const PostFeedPage(posts: [], page: 2, hasMore: false));

    await useCase(page: 2, pageSize: 10);

    verify(() => repo.getPostFeed(page: 2, pageSize: 10)).called(1);
  });
}
