import { describe, it, expect } from 'vitest';
import { levelForPoints } from '../../src/badges/levelForPoints';
import type { LevelConfig } from '../../src/badges/types';

const config: LevelConfig = {
  thresholds: [
    { level: 1, cumulative: 0 },
    { level: 2, cumulative: 30 },
    { level: 3, cumulative: 80 },
    { level: 10, cumulative: 1800 },
  ],
  perLevelAbove10: 500,
};

describe('levelForPoints', () => {
  it('returns 1 for 0 points', () => {
    expect(levelForPoints(0, config)).toBe(1);
  });
  it('returns 1 just below the level-2 threshold', () => {
    expect(levelForPoints(29, config)).toBe(1);
  });
  it('returns 2 exactly at the level-2 threshold', () => {
    expect(levelForPoints(30, config)).toBe(2);
  });
  it('returns 10 at the level-10 cumulative', () => {
    expect(levelForPoints(1800, config)).toBe(10);
  });
  it('extrapolates linearly beyond level 10', () => {
    expect(levelForPoints(2300, config)).toBe(11);
    expect(levelForPoints(2800, config)).toBe(12);
    expect(levelForPoints(2299, config)).toBe(10);
  });
});
