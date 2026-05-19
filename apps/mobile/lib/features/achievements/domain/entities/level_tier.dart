class LevelThreshold {
  final int level;
  final int cumulative;
  const LevelThreshold({required this.level, required this.cumulative});
}

class LevelConfig {
  final List<LevelThreshold> thresholds;
  final int perLevelAbove10;
  const LevelConfig({required this.thresholds, required this.perLevelAbove10});
}

class LevelProgress {
  final int currentLevel;
  final int pointsIntoLevel;
  final int pointsToNextLevel;
  final double fractionToNext;
  const LevelProgress({
    required this.currentLevel,
    required this.pointsIntoLevel,
    required this.pointsToNextLevel,
    required this.fractionToNext,
  });
}
