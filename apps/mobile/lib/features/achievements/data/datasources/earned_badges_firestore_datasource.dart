import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unishare_mobile/features/achievements/data/models/earned_badge_dto.dart';

class EarnedBadgesFirestoreDatasource {
  final FirebaseFirestore _db;
  EarnedBadgesFirestoreDatasource(this._db);

  Stream<List<EarnedBadgeDto>> watch(String uid) {
    return _db
        .collection('users/$uid/earnedBadges')
        .orderBy('earnedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(EarnedBadgeDto.fromSnapshot).toList());
  }
}
