import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/public_user.dart';

/// Direct snapshot mapper for `users_public/{uid}`. Not Freezed — the
/// shape is simple and we never need copyWith / equality / fromJson, just
/// snapshot → entity conversion.
class PublicUserDto {
  static PublicUser? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    if (data == null) return null;
    final name = data['name'];
    if (name is! String || name.isEmpty) return null;

    final rawDisplayed = data['displayedBadges'];
    final displayed = rawDisplayed is List
        ? rawDisplayed.whereType<String>().toList(growable: false)
        : const <String>[];

    final selectedTitleRaw = data['selectedTitle'];
    final selectedTitle =
        selectedTitleRaw is String && selectedTitleRaw.isNotEmpty
        ? selectedTitleRaw
        : null;

    final photoUrlRaw = data['photoUrl'];
    final photoUrl =
        photoUrlRaw is String && photoUrlRaw.isNotEmpty ? photoUrlRaw : null;

    final bioRaw = data['bio'];
    final bio = bioRaw is String && bioRaw.isNotEmpty ? bioRaw : null;

    return PublicUser(
      uid: snap.id,
      name: name,
      photoUrl: photoUrl,
      bio: bio,
      level: (data['level'] as num?)?.toInt() ?? 1,
      selectedTitle: selectedTitle,
      displayedBadges: displayed,
    );
  }
}
