import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unishare_mobile/features/achievements/data/models/public_user_dto.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/public_user.dart';

class PublicUserFirestoreDatasource {
  final FirebaseFirestore _db;
  PublicUserFirestoreDatasource(this._db);

  Stream<PublicUser?> watch(String uid) {
    return _db
        .doc('users_public/$uid')
        .snapshots()
        .map(PublicUserDto.fromSnapshot);
  }
}
