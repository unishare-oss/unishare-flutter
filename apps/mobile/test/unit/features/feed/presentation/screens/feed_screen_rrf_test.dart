import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/feed/presentation/screens/feed_screen.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';

Post _post(String id, {PostType type = PostType.lectureNote}) {
  return Post(
    id: id,
    title: id,
    description: '',
    authorId: 'a',
    authorName: 'A',
    authorAvatar: '',
    postType: type,
    year: 1,
    courseId: 'c',
    postingIdentity: PostingIdentity.named,
    semester: 1,
    moduleNumber: '1',
    mediaUrls: const [],
    mediaTypes: const [],
    tags: const [],
    likesCount: 0,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  group('hybridRankRRF', () {
    test('shared posts outrank single-source posts', () {
      final keyword = [_post('A'), _post('B')];
      final semantic = [_post('A'), _post('C')];
      final ranked = hybridRankRRF(keyword, semantic);
      // A appears in both → highest score, should be first.
      expect(ranked.first.id, 'A');
      expect(ranked.length, 3);
    });

    test('empty semantic returns keyword list unchanged', () {
      final keyword = [_post('A'), _post('B'), _post('C')];
      final ranked = hybridRankRRF(keyword, const []);
      expect(ranked.map((p) => p.id).toList(), ['A', 'B', 'C']);
    });

    test('empty keyword returns semantic in order', () {
      final semantic = [_post('X'), _post('Y')];
      final ranked = hybridRankRRF(const [], semantic);
      expect(ranked.map((p) => p.id).toList(), ['X', 'Y']);
    });

    test('respects per-source rank — dual-source beats single-source', () {
      final keyword = [_post('A'), _post('C'), _post('B')];
      final semantic = [_post('B'), _post('A')];
      final ranked = hybridRankRRF(keyword, semantic);
      final ids = ranked.map((p) => p.id).toList();
      // C is single-source mid-rank; A and B are dual-source → they should come before C.
      expect(ids.indexOf('C'), greaterThan(ids.indexOf('A')));
      expect(ids.indexOf('C'), greaterThan(ids.indexOf('B')));
    });

    test('caps result list at the provided cap', () {
      final keyword = List.generate(20, (i) => _post('k$i'));
      final semantic = List.generate(20, (i) => _post('s$i'));
      final ranked = hybridRankRRF(keyword, semantic, cap: 5);
      expect(ranked.length, 5);
    });
  });
}
