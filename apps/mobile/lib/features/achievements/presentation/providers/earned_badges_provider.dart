import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';

part 'earned_badges_provider.g.dart';

@riverpod
Stream<List<EarnedBadge>> earnedBadges(Ref ref, String uid) {
  return ref.watch(badgeRepositoryProvider).watchEarnedBadges(uid);
}
