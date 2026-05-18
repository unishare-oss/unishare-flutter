import 'package:unishare_mobile/features/achievements/domain/repositories/gamification_repository.dart';

class DisplayedBadgesException implements Exception {
  final String message;
  const DisplayedBadgesException(this.message);
  @override
  String toString() => 'DisplayedBadgesException: $message';
}

void validateDisplayedBadgesSelection({
  required List<String> proposed,
  required Set<String> earnedIds,
}) {
  if (proposed.length > 3) {
    throw const DisplayedBadgesException('At most 3 badges may be displayed.');
  }
  if (proposed.toSet().length != proposed.length) {
    throw const DisplayedBadgesException('Duplicate badges are not allowed.');
  }
  for (final id in proposed) {
    if (!earnedIds.contains(id)) {
      throw DisplayedBadgesException('Badge "$id" is not earned.');
    }
  }
}

class SetDisplayedBadges {
  final GamificationRepository repo;
  const SetDisplayedBadges(this.repo);

  Future<void> call({
    required String uid,
    required List<String> proposed,
    required Set<String> earnedIds,
  }) async {
    validateDisplayedBadgesSelection(
      proposed: proposed,
      earnedIds: earnedIds,
    );
    await repo.setDisplayedBadges(uid, proposed);
  }
}
