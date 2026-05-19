import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/post/data/repositories/reaction_repository_impl.dart';
import 'package:unishare_mobile/features/post/domain/repositories/reaction_repository.dart';

final reactionRepositoryProvider = Provider<ReactionRepository>(
  (_) => ReactionRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  ),
);

final userReactionsProvider = StreamProvider.autoDispose
    .family<Set<String>, String>(
      (ref, postId) =>
          ref.watch(reactionRepositoryProvider).watchUserReactions(postId),
    );
