import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/achievements/data/repositories/gamification_repository_impl.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/user_gamification.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/user_stats.dart';
import 'package:unishare_mobile/features/achievements/domain/repositories/gamification_repository.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';

part 'user_gamification_provider.g.dart';

@Riverpod(keepAlive: true)
GamificationRepository gamificationRepository(Ref ref) {
  return GamificationRepositoryImpl(ref.watch(badgeFirestoreDatasourceProvider));
}

@riverpod
Stream<UserGamification> userGamification(Ref ref, String uid) {
  return ref.watch(gamificationRepositoryProvider).watchGamification(uid);
}

@riverpod
Stream<UserStats> userStats(Ref ref, String uid) {
  return ref.watch(gamificationRepositoryProvider).watchStats(uid);
}
