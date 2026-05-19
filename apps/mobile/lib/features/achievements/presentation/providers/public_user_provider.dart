import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/achievements/data/datasources/public_user_firestore_datasource.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/public_user.dart';

part 'public_user_provider.g.dart';

@Riverpod(keepAlive: true)
PublicUserFirestoreDatasource publicUserDatasource(Ref ref) {
  return PublicUserFirestoreDatasource(FirebaseFirestore.instance);
}

/// Streams the public-safe projection of `users/{uid}`. Riverpod
/// auto-dedupes per-uid subscriptions, so multiple PostCards rendering
/// posts by the same author share a single Firestore listener.
@riverpod
Stream<PublicUser?> publicUser(Ref ref, String uid) {
  return ref.watch(publicUserDatasourceProvider).watch(uid);
}
