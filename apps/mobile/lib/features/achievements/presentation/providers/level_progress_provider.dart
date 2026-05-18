import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/level_tier.dart';
import 'package:unishare_mobile/features/achievements/domain/usecases/compute_level_progress.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/user_gamification_provider.dart';

part 'level_progress_provider.g.dart';

@Riverpod(keepAlive: true)
Future<LevelConfig> levelConfig(Ref ref) async {
  final snap = await FirebaseFirestore.instance.doc('app_config/levels').get();
  final data = snap.data() ?? const <String, dynamic>{};
  final raw = (data['thresholds'] as List?) ?? const [];
  final thresholds = raw
      .whereType<Map>()
      .map(
        (t) => LevelThreshold(
          level: (t['level'] as num?)?.toInt() ?? 1,
          cumulative: (t['cumulative'] as num?)?.toInt() ?? 0,
        ),
      )
      .toList(growable: false);
  return LevelConfig(
    thresholds: thresholds.isEmpty
        ? const [LevelThreshold(level: 1, cumulative: 0)]
        : thresholds,
    perLevelAbove10: (data['perLevelAbove10'] as num?)?.toInt() ?? 500,
  );
}

@riverpod
LevelProgress? levelProgress(Ref ref, String uid) {
  final gamification = ref.watch(userGamificationProvider(uid)).asData?.value;
  final config = ref.watch(levelConfigProvider).asData?.value;
  if (gamification == null || config == null) return null;
  return ComputeLevelProgress(config)(gamification.totalPoints);
}
