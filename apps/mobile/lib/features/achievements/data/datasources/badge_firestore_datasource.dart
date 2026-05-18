import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unishare_mobile/features/achievements/data/models/badge_dto.dart';
import 'package:unishare_mobile/features/achievements/data/models/user_gamification_dto.dart';
import 'package:unishare_mobile/features/achievements/data/models/user_stats_dto.dart';

class BadgeFirestoreDatasource {
  final FirebaseFirestore _db;
  BadgeFirestoreDatasource(this._db);

  Stream<List<BadgeDto>> watchCatalog() {
    return _db
        .collection('badges')
        .where('active', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((s) => s.docs.map(BadgeDto.fromSnapshot).toList());
  }

  Stream<UserGamificationDto> watchGamification(String uid) {
    return _db.doc('users/$uid').snapshots().map((s) {
      final map = (s.data()?['gamification'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};
      return UserGamificationDto.fromJson(map);
    });
  }

  Stream<UserStatsDto> watchStats(String uid) {
    return _db.doc('users/$uid').snapshots().map((s) {
      final map = (s.data()?['stats'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};
      return UserStatsDto.fromJson(map);
    });
  }

  Future<void> setDisplayedBadges(String uid, List<String> badgeIds) {
    return _db.doc('users/$uid').update({
      'gamification.displayedBadges': badgeIds,
    });
  }

  Future<void> setSelectedTitle(String uid, String? badgeId) {
    return _db.doc('users/$uid').update({
      'gamification.selectedTitle': badgeId,
    });
  }
}
