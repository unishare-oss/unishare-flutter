import 'package:hive_flutter/hive_flutter.dart';

import 'package:unishare_mobile/features/saved/data/models/saved_post_hive_model.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post_snapshot.dart';

class SavedPostHiveDatasource {
  Box<SavedPostHiveModel> get _box =>
      Hive.box<SavedPostHiveModel>('saved_posts');

  Stream<List<SavedPost>> watchAll() async* {
    yield _readAll();
    await for (final _ in _box.watch()) {
      yield _readAll();
    }
  }

  List<SavedPost> readAll() => _readAll();

  List<SavedPost> _readAll() {
    final values = _box.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return values.map((m) => m.toEntity()).toList();
  }

  Future<void> save(String postId, SavedPostSnapshot snapshot) async {
    if (_box.containsKey(postId)) return;
    await _box.put(
      postId,
      SavedPostHiveModel(
        postId: postId,
        savedAt: DateTime.now(),
        title: snapshot.title,
        authorName: snapshot.authorName,
        authorAvatar: snapshot.authorAvatar,
        courseId: snapshot.courseId,
        postType: snapshot.postType,
        tags: List<String>.from(snapshot.tags),
        commentsCount: snapshot.commentsCount,
      ),
    );
  }

  Future<void> remove(String postId) => _box.delete(postId);

  bool contains(String postId) => _box.containsKey(postId);

  Stream<bool> watchContains(String postId) async* {
    yield _box.containsKey(postId);
    await for (final _ in _box.watch(key: postId)) {
      yield _box.containsKey(postId);
    }
  }

  Future<void> clearAll() => _box.clear();
}
