import 'package:unishare_mobile/features/achievements/domain/entities/user_gamification.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/user_stats.dart';

abstract class GamificationRepository {
  Stream<UserGamification> watchGamification(String uid);
  Stream<UserStats> watchStats(String uid);
  Future<void> setDisplayedBadges(String uid, List<String> badgeIds);
  Future<void> setSelectedTitle(String uid, String? badgeId);
}
