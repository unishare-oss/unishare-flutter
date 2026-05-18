import 'package:unishare_mobile/features/achievements/data/datasources/badge_firestore_datasource.dart';
import 'package:unishare_mobile/features/achievements/data/datasources/earned_badges_firestore_datasource.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';
import 'package:unishare_mobile/features/achievements/domain/repositories/badge_repository.dart';

class BadgeRepositoryImpl implements BadgeRepository {
  final BadgeFirestoreDatasource _catalog;
  final EarnedBadgesFirestoreDatasource _earned;
  BadgeRepositoryImpl(this._catalog, this._earned);

  @override
  Stream<List<AchievementBadge>> watchCatalog() {
    return _catalog
        .watchCatalog()
        .map((dtos) => dtos.map((d) => d.toEntity()).toList(growable: false));
  }

  @override
  Stream<List<EarnedBadge>> watchEarnedBadges(String uid) {
    return _earned
        .watch(uid)
        .map((dtos) => dtos.map((d) => d.toEntity()).toList(growable: false));
  }
}
