import 'package:unishare_mobile/features/post/domain/entities/comment.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';

Post fakePost({String id = 'post-1'}) => Post(
  id: id,
  authorId: 'author-1',
  authorName: 'Test Author',
  authorAvatar: '',
  title: 'Test Title',
  body: 'Test body content',
  mediaUrls: const [],
  tags: const ['flutter'],
  likesCount: 5,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Comment fakeComment({String id = 'c-1'}) => Comment(
  id: id,
  authorId: 'author-1',
  authorName: 'Alice',
  authorAvatar: '',
  body: 'Great post!',
  createdAt: DateTime(2026, 1, 1, 12, 0),
);
