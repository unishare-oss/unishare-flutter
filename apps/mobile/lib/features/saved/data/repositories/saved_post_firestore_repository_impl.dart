import 'package:firebase_auth/firebase_auth.dart';

import 'package:unishare_mobile/features/saved/data/datasources/saved_post_firestore_datasource.dart';
import 'package:unishare_mobile/features/saved/data/datasources/saved_post_hive_datasource.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post_snapshot.dart';
import 'package:unishare_mobile/features/saved/domain/repositories/saved_post_repository.dart';

class SavedPostFirestoreRepositoryImpl implements SavedPostRepository {
  const SavedPostFirestoreRepositoryImpl({
    required this.firestoreDatasource,
    required this.hiveDatasource,
  });

  final SavedPostFirestoreDatasource firestoreDatasource;
  final SavedPostHiveDatasource hiveDatasource;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Stream<List<SavedPost>> watchSavedPosts() =>
      firestoreDatasource.watchAll(_uid);

  @override
  Future<void> savePost(String postId, SavedPostSnapshot snapshot) =>
      firestoreDatasource.save(_uid, postId, snapshot);

  @override
  Future<void> unsavePost(String postId) =>
      firestoreDatasource.unsave(_uid, postId);

  @override
  Stream<bool> isPostSaved(String postId) =>
      firestoreDatasource.watchSaved(_uid, postId);

  @override
  Future<void> mergeFrom(List<SavedPost> guestSaves) async {
    await firestoreDatasource.mergeAll(_uid, guestSaves);
    await hiveDatasource.clearAll();
  }
}
