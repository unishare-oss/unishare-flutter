import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unishare_mobile/features/post_feed/data/datasources/post_firestore_datasource.dart';
import 'package:unishare_mobile/features/post_feed/data/models/post_model.dart';
import 'package:unishare_mobile/features/post_feed/data/repositories/post_repository_impl.dart';

class MockPostFirestoreDataSource extends Mock
    implements PostFirestoreDataSource {}

PostModel _fakeModel({String id = 'p1', bool isLiked = false}) => PostModel(
      id: id,
      authorId: 'u1',
      authorName: 'Alice',
      authorAvatar: '',
      title: 'Test Post',
      body: 'Body text',
      likesCount: 3,
      isLikedByCurrentUser: isLiked,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

void main() {
  late MockPostFirestoreDataSource dataSource;
  late PostRepositoryImpl repo;

  setUp(() {
    dataSource = MockPostFirestoreDataSource();
    repo = PostRepositoryImpl(dataSource);
  });

  group('getPostFeed', () {
    test('maps models to entities and sets hasMore correctly', () async {
      final models = List.generate(20, (i) => _fakeModel(id: 'p$i'));
      when(() => dataSource.getPostFeed(page: 0, pageSize: 20))
          .thenAnswer((_) async => models);

      final result = await repo.getPostFeed();

      expect(result.posts.length, 20);
      expect(result.page, 0);
      expect(result.hasMore, isTrue);
      expect(result.posts.first.id, 'p0');
    });

    test('hasMore is false when fewer than pageSize posts returned', () async {
      when(() => dataSource.getPostFeed(page: 0, pageSize: 20))
          .thenAnswer((_) async => [_fakeModel()]);

      final result = await repo.getPostFeed();

      expect(result.hasMore, isFalse);
    });
  });

  group('getPost', () {
    test('maps model to entity including isLikedByCurrentUser', () async {
      when(() => dataSource.getPost('p1'))
          .thenAnswer((_) async => _fakeModel(isLiked: true));

      final post = await repo.getPost('p1');

      expect(post.id, 'p1');
      expect(post.isLikedByCurrentUser, isTrue);
    });
  });

  group('toggleLike', () {
    test('delegates to data source with correct arguments', () async {
      when(() => dataSource.toggleLike('p1', liked: true))
          .thenAnswer((_) async {});

      await repo.toggleLike('p1', liked: true);

      verify(() => dataSource.toggleLike('p1', liked: true)).called(1);
    });
  });

  group('deletePost', () {
    test('delegates to data source', () async {
      when(() => dataSource.deletePost('p1')).thenAnswer((_) async {});

      await repo.deletePost('p1');

      verify(() => dataSource.deletePost('p1')).called(1);
    });
  });
}
