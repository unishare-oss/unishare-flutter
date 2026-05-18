import 'package:unishare_mobile/features/achievements/data/datasources/badge_firestore_datasource.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/user_gamification.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/user_stats.dart';
import 'package:unishare_mobile/features/achievements/domain/repositories/gamification_repository.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  final BadgeFirestoreDatasource _ds;
  GamificationRepositoryImpl(this._ds);

  @override
  Stream<UserGamification> watchGamification(String uid) =>
      _ds.watchGamification(uid).map((d) => d.toEntity());

  @override
  Stream<UserStats> watchStats(String uid) =>
      _ds.watchStats(uid).map((d) => d.toEntity());

  @override
  Future<void> setDisplayedBadges(String uid, List<String> badgeIds) =>
      _ds.setDisplayedBadges(uid, badgeIds);

  @override
  Future<void> setSelectedTitle(String uid, String? badgeId) =>
      _ds.setSelectedTitle(uid, badgeId);
}
