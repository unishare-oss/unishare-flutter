import 'package:unishare_mobile/features/saved/data/datasources/saved_post_hive_datasource.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post_snapshot.dart';
import 'package:unishare_mobile/features/saved/domain/repositories/saved_post_repository.dart';

class SavedPostHiveRepositoryImpl implements SavedPostRepository {
  const SavedPostHiveRepositoryImpl(this._datasource);
  final SavedPostHiveDatasource _datasource;

  @override
  Stream<List<SavedPost>> watchSavedPosts() => _datasource.watchAll();

  @override
  Future<void> savePost(String postId, SavedPostSnapshot snapshot) =>
      _datasource.save(postId, snapshot);

  @override
  Future<void> unsavePost(String postId) => _datasource.remove(postId);

  @override
  Stream<bool> isPostSaved(String postId) => _datasource.watchContains(postId);

  @override
  Future<void> mergeFrom(List<SavedPost> guestSaves) async {
    // Hive impl is the guest store — mergeFrom is a no-op here.
    // The Firestore impl handles the actual merge and clears this box.
  }
}
