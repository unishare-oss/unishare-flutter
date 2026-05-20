import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/achievements/data/datasources/badge_firestore_datasource.dart';
import 'package:unishare_mobile/features/achievements/data/datasources/earned_badges_firestore_datasource.dart';
import 'package:unishare_mobile/features/achievements/data/repositories/badge_repository_impl.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/repositories/badge_repository.dart';

part 'badge_catalog_provider.g.dart';

@Riverpod(keepAlive: true)
BadgeFirestoreDatasource badgeFirestoreDatasource(Ref ref) {
  return BadgeFirestoreDatasource(FirebaseFirestore.instance);
}

@Riverpod(keepAlive: true)
EarnedBadgesFirestoreDatasource earnedBadgesFirestoreDatasource(Ref ref) {
  return EarnedBadgesFirestoreDatasource(FirebaseFirestore.instance);
}

@Riverpod(keepAlive: true)
BadgeRepository badgeRepository(Ref ref) {
  return BadgeRepositoryImpl(
    ref.watch(badgeFirestoreDatasourceProvider),
    ref.watch(earnedBadgesFirestoreDatasourceProvider),
  );
}

@riverpod
Stream<List<AchievementBadge>> badgeCatalog(Ref ref) {
  return ref.watch(badgeRepositoryProvider).watchCatalog();
}
