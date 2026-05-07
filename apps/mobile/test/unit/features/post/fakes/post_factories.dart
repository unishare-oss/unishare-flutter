import 'package:unishare_mobile/features/post/domain/entities/comment.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';

Post fakePost({String id = 'post-1'}) => Post(
  id: id,
  authorId: 'author-1',
  authorName: 'Test Author',
  authorAvatar: '',
  postType: PostType.lectureNote,
  year: 1,
  courseId: 'csc101',
  title: 'Test Title',
  description: 'Test body content',
  postingIdentity: PostingIdentity.named,
  semester: 1,
  moduleNumber: '',
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
