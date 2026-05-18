import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/earned_badges_provider.dart';

part 'new_badge_alert_provider.g.dart';

const _kBoxName = 'achievements_alerts';
const _kLastSeenKey = 'lastSeenAt';

Future<void> openAchievementsAlertsBox() async {
  if (!Hive.isBoxOpen(_kBoxName)) {
    await Hive.openBox(_kBoxName);
  }
}

@riverpod
class NewBadgeAlertNotifier extends _$NewBadgeAlertNotifier {
  @override
  List<EarnedBadge> build(String uid) {
    final earned =
        ref.watch(earnedBadgesProvider(uid)).asData?.value ?? const [];
    final lastSeen = _readLastSeen();
    final unread = earned
        .where((e) => e.earnedAt.isAfter(lastSeen))
        .toList(growable: false);
    return List.of(unread)..sort((a, b) => a.earnedAt.compareTo(b.earnedAt));
  }

  DateTime _readLastSeen() {
    final box = Hive.box(_kBoxName);
    final ts = box.get(_kLastSeenKey) as int?;
    if (ts == null) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  Future<void> markSeen(EarnedBadge earned) async {
    final box = Hive.box(_kBoxName);
    final cur = _readLastSeen();
    final next = earned.earnedAt.isAfter(cur) ? earned.earnedAt : cur;
    await box.put(_kLastSeenKey, next.millisecondsSinceEpoch);
    ref.invalidateSelf();
  }
}
