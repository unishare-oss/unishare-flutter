import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/level_tier.dart';
import 'package:unishare_mobile/features/achievements/domain/usecases/compute_level_progress.dart';

void main() {
  const config = LevelConfig(
    thresholds: [
      LevelThreshold(level: 1, cumulative: 0),
      LevelThreshold(level: 2, cumulative: 30),
      LevelThreshold(level: 3, cumulative: 80),
      LevelThreshold(level: 10, cumulative: 1800),
    ],
    perLevelAbove10: 500,
  );

  final compute = const ComputeLevelProgress(config);

  group('ComputeLevelProgress', () {
    test('0 points → Lv 1, 0 into level, 30 to next', () {
      final r = compute(0);
      expect(r.currentLevel, 1);
      expect(r.pointsIntoLevel, 0);
      expect(r.pointsToNextLevel, 30);
      expect(r.fractionToNext, 0.0);
    });

    test('29 points → Lv 1, 29 into level, 1 to next', () {
      final r = compute(29);
      expect(r.currentLevel, 1);
      expect(r.pointsIntoLevel, 29);
      expect(r.pointsToNextLevel, 1);
    });

    test('30 points → Lv 2 exactly', () {
      expect(compute(30).currentLevel, 2);
    });

    test('1800 points → Lv 10', () {
      expect(compute(1800).currentLevel, 10);
    });

    test('past Lv 10 extrapolates by perLevelAbove10', () {
      expect(compute(2300).currentLevel, 11);
      expect(compute(2800).currentLevel, 12);
      expect(compute(2299).currentLevel, 10);
    });
  });
}
