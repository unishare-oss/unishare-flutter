import 'package:unishare_mobile/features/achievements/domain/repositories/gamification_repository.dart';
import 'package:unishare_mobile/features/achievements/domain/usecases/set_displayed_badges.dart';

class SetSelectedTitle {
  final GamificationRepository repo;
  const SetSelectedTitle(this.repo);

  Future<void> call({
    required String uid,
    required String? badgeId,
    required Set<String> earnedIds,
  }) async {
    if (badgeId != null && !earnedIds.contains(badgeId)) {
      throw DisplayedBadgesException('Title "$badgeId" is not earned.');
    }
    await repo.setSelectedTitle(uid, badgeId);
  }
}
