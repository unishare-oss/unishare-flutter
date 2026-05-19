import 'package:unishare_mobile/features/achievements/domain/entities/level_tier.dart';

class ComputeLevelProgress {
  final LevelConfig config;
  const ComputeLevelProgress(this.config);

  LevelProgress call(int totalPoints) {
    final sorted = [...config.thresholds]
      ..sort((a, b) => a.cumulative.compareTo(b.cumulative));

    var lastLevel = sorted.isEmpty ? 1 : sorted.first.level;
    var lastCumulative = sorted.isEmpty ? 0 : sorted.first.cumulative;
    for (final t in sorted) {
      if (totalPoints >= t.cumulative) {
        lastLevel = t.level;
        lastCumulative = t.cumulative;
      } else {
        break;
      }
    }

    var currentLevel = lastLevel;
    if (lastLevel >= 10 && config.perLevelAbove10 > 0) {
      final extra = (totalPoints - lastCumulative) ~/ config.perLevelAbove10;
      currentLevel = lastLevel + extra;
    }

    final nextCumulative = _nextCumulative(sorted, totalPoints, lastCumulative);
    final intoLevel = totalPoints - lastCumulative;
    final toNext = nextCumulative - totalPoints;
    final span = nextCumulative - lastCumulative;
    return LevelProgress(
      currentLevel: currentLevel,
      pointsIntoLevel: intoLevel,
      pointsToNextLevel: toNext,
      fractionToNext: span <= 0 ? 1.0 : intoLevel / span,
    );
  }

  int _nextCumulative(
    List<LevelThreshold> sorted,
    int totalPoints,
    int lastCumulative,
  ) {
    for (final t in sorted) {
      if (t.cumulative > totalPoints) return t.cumulative;
    }
    // Past the last seeded threshold (typically level 10) — use linear
    // extrapolation so the progress bar still tracks toward the next level.
    final stepsPast = (totalPoints - lastCumulative) ~/ config.perLevelAbove10;
    return lastCumulative + config.perLevelAbove10 * (stepsPast + 1);
  }
}
