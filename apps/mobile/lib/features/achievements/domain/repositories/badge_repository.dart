import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';

abstract class BadgeRepository {
  Stream<List<AchievementBadge>> watchCatalog();
  Stream<List<EarnedBadge>> watchEarnedBadges(String uid);
}
